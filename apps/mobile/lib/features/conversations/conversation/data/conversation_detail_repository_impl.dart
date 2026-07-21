import 'dart:async';

import '../../../../services/crypto_service.dart';
import '../../../../services/identity_service.dart';
import '../../../../services/local_cache_service.dart';
import '../../../../services/messaging_service.dart';
import '../../../../services/websocket_service.dart';
import '../domain/conversation_detail_repository.dart';
import '../models/message.dart';

class ConversationDetailRepositoryImpl
    implements ConversationDetailRepository {
  final MessagingService _messaging;
  final WebSocketService _ws;
  final CryptoService _crypto;
  final IdentityService _identity;
  final CacheService _cache;
  final String? Function() _tokenProvider;
  final String? Function() _userIdProvider;
  final Map<String, DetailRepositoryStatus> _statusCache = {};
  final Map<String, List<int>> _sharedSecrets = {};
  StreamSubscription<WsEvent>? _wsSub;
  StreamController<Message>? _messageController;

  ConversationDetailRepositoryImpl({
    required this._messaging,
    required this._ws,
    required this._crypto,
    required this._identity,
    required this._cache,
    required this._tokenProvider,
    required this._userIdProvider,
  });

  String get _token {
    final t = _tokenProvider();
    if (t == null) throw Exception('Not authenticated');
    return t;
  }

  String get _currentUserId {
    final u = _userIdProvider();
    if (u == null) throw Exception('No current user');
    return u;
  }

  Future<List<int>?> _ensureSecret(String conversationId) async {
    if (_sharedSecrets.containsKey(conversationId)) {
      return _sharedSecrets[conversationId];
    }
    try {
      final token = _token;
      // Try group key first (for group conversations)
      try {
        final encryptedKey = await _messaging.getGroupKey(token, conversationId);
        if (encryptedKey.isNotEmpty) {
          final conversations = await _messaging.listConversations(token);
          final match = conversations.where((c) => c.id == conversationId).firstOrNull;
          if (match != null) {
            final creator = match.participants
                .where((p) => p.userId != _currentUserId)
                .firstOrNull;
            if (creator != null) {
              final creatorPubKey = await _identity.getExchangeKey(token, creator.userId);
              if (creatorPubKey.isNotEmpty) {
                final secret = await _crypto.decryptGroupKey(encryptedKey, creatorPubKey);
                if (secret.isNotEmpty) {
                  _sharedSecrets[conversationId] = secret;
                  return secret;
                }
              }
            }
          }
        }
      } catch (_) {
        // No group key — likely a 1:1 conversation; fall through to ECDH
      }
      // Fall back to ECDH shared secret (1:1 conversations)
      final conversations = await _messaging.listConversations(token);
      final match = conversations.where((c) => c.id == conversationId).firstOrNull;
      if (match == null) return null;
      final other = match.participants
          .where((p) => p.userId != _currentUserId)
          .firstOrNull;
      if (other == null) return null;
      final pubKey = await _identity.getExchangeKey(token, other.userId);
      if (pubKey.isEmpty) return null;
      final secret = await _crypto.deriveSharedSecret(pubKey);
      _sharedSecrets[conversationId] = secret;
      return secret;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final token = _token;
    try {
      final infos = await _messaging.listMessages(token, conversationId);
      final secret = await _ensureSecret(conversationId);
      List<Message> results;
      if (secret == null) {
        results = infos.map((m) => _mapMessageInfo(m)).toList();
      } else {
        results = [];
        for (final info in infos) {
          results.add(await _decryptMessage(info, secret));
        }
      }
      await _cache.cacheMessages(conversationId, results);
      return results;
    } catch (_) {
      final cached = await _cache.getCachedMessages(conversationId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Message> _decryptMessage(MessageInfo info, List<int> secret) async {
    try {
      final decrypted = await _crypto.decryptWithSharedKey(info.ciphertext, secret);
      return _mapMessageInfo(info, content: decrypted);
    } catch (_) {
      return _mapMessageInfo(info);
    }
  }

  @override
  Future<bool> sendMessage(String conversationId, String plaintext) async {
    try {
      final token = _token;
      final secret = await _ensureSecret(conversationId);
      final ciphertext = secret != null
          ? await _crypto.encryptWithSharedKey(plaintext, secret)
          : plaintext;
      final info =
          await _messaging.sendMessage(token, conversationId, ciphertext);
      final message = _mapMessageInfo(info, content: plaintext);
      _messageController?.add(message);
      await _appendToMessageCache(conversationId, message);
      return true;
    } catch (_) {
      await _cache.addPendingMessage(conversationId, plaintext);
      return false;
    }
  }

  Future<void> _appendToMessageCache(
      String conversationId, Message message) async {
    try {
      final cached = await _cache.getCachedMessages(conversationId);
      if (cached != null) {
        final updated = [...cached, message];
        await _cache.cacheMessages(conversationId, updated);
      } else {
        await _cache.cacheMessages(conversationId, [message]);
      }
    } catch (_) {}
  }

  @override
  Future<bool> completeConversation(String conversationId) async {
    try {
      final token = _token;
      await _messaging.completeConversation(token, conversationId);
      _statusCache[conversationId] = DetailRepositoryStatus.completed;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> destroyConversation(String conversationId) async {
    try {
      final token = _token;
      await _messaging.destroyConversation(token, conversationId);
      _statusCache[conversationId] = DetailRepositoryStatus.destroyed;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DetailRepositoryStatus> getStatus(String conversationId) async {
    if (_statusCache.containsKey(conversationId)) {
      return _statusCache[conversationId]!;
    }
    try {
      final token = _token;
      final conversations = await _messaging.listConversations(token);
      final match = conversations.where((c) => c.id == conversationId).firstOrNull;
      if (match == null) return DetailRepositoryStatus.destroyed;
      final status = _mapApiStatus(match.status);
      _statusCache[conversationId] = status;
      return status;
    } catch (_) {
      return DetailRepositoryStatus.active;
    }
  }

  @override
  Stream<Message> messageStream(String conversationId) {
    _messageController?.close();
    _messageController = StreamController<Message>.broadcast();

    _wsSub?.cancel();
    _wsSub = _ws.eventStream.listen((event) async {
      if (event.type == WsEventType.messageReceived && event.data is Map) {
        final data = event.data as Map<String, dynamic>;
        final msgConvId = data['conversation_id'] as String?;
        if (msgConvId == conversationId) {
          final ciphertext = data['ciphertext'] as String? ?? '';
          final secret = _sharedSecrets[conversationId];
          String content;
          if (secret != null) {
            try {
              content = await _crypto.decryptWithSharedKey(ciphertext, secret);
            } catch (_) {
              content = ciphertext;
            }
          } else {
            content = ciphertext;
          }
          final message = Message(
            id: data['id'] as String? ?? '',
            senderId: data['sender_id'] as String? ?? '',
            senderName: _resolveSenderName(data['sender_id'] as String? ?? ''),
            content: content,
            createdAt: _tryParseDate(data['created_at'] as String?),
            status: MessageStatus.sent,
          );
          _messageController!.add(message);
        }
      }
    });

    return _messageController!.stream;
  }

  @override
  Future<void> dispose() async {
    await _wsSub?.cancel();
    await _messageController?.close();
  }

  @override
  Future<void> flushPendingMessages(String conversationId) async {
    final pending = await _cache.getPendingMessages(conversationId);
    if (pending.isEmpty) return;
    final token = _token;
    final secret = await _ensureSecret(conversationId);
    final stillPending = <PendingMessage>[];
    for (final msg in pending) {
      try {
        final ciphertext = secret != null
            ? await _crypto.encryptWithSharedKey(msg.plaintext, secret)
            : msg.plaintext;
        await _messaging.sendMessage(token, conversationId, ciphertext);
      } catch (_) {
        stillPending.add(msg);
      }
    }
    if (stillPending.isEmpty) {
      await _cache.clearPendingMessages(conversationId);
    }
  }

  Message _mapMessageInfo(MessageInfo info, {String? content}) {
    return Message(
      id: info.id,
      senderId: info.senderId,
      senderName: _resolveSenderName(info.senderId),
      content: content ?? info.ciphertext,
      createdAt: DateTime.tryParse(info.createdAt) ?? DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  String _resolveSenderName(String senderId) {
    if (senderId == _currentUserId) return 'You';
    return 'Unknown';
  }

  DetailRepositoryStatus _mapApiStatus(String status) {
    switch (status) {
      case 'active':
        return DetailRepositoryStatus.active;
      case 'completed':
        return DetailRepositoryStatus.completed;
      case 'destroyed':
        return DetailRepositoryStatus.destroyed;
      default:
        return DetailRepositoryStatus.active;
    }
  }

  DateTime _tryParseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
