import 'dart:async';
import 'dart:convert';

import '../../../../services/crypto_service.dart';
import '../../../../services/double_ratchet.dart';
import '../../../../services/identity_service.dart';
import '../../../../services/local_cache_service.dart';
import '../../../../services/messaging_service.dart';
import '../../../../services/ratchet_session_store.dart';
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
  final RatchetSessionStore _sessionStore;
  final Map<String, DetailRepositoryStatus> _statusCache = {};
  final Map<String, List<int>> _sharedSecrets = {};
  final Map<String, DoubleRatchetSession> _sessions = {};
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
    RatchetSessionStore? sessionStore,
  }) : _sessionStore = sessionStore ?? RatchetSessionStore();

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

  Future<List<int>?> _tryGroupKey(String conversationId) async {
    try {
      final token = _token;
      final encryptedKey =
          await _messaging.getGroupKey(token, conversationId);
      if (encryptedKey.isNotEmpty) {
        final conversations = await _messaging.listConversations(token);
        final match =
            conversations.where((c) => c.id == conversationId).firstOrNull;
        if (match != null) {
          final creator = match.participants
              .where((p) => p.userId != _currentUserId)
              .firstOrNull;
          if (creator != null) {
            final creatorPubKey =
                await _identity.getExchangeKey(token, creator.userId);
            if (creatorPubKey.isNotEmpty) {
              final secret =
                  await _crypto.decryptGroupKey(encryptedKey, creatorPubKey);
              if (secret.isNotEmpty) {
                _sharedSecrets[conversationId] = secret;
                return secret;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<int>?> _ensureSecret(String conversationId) async {
    if (_sharedSecrets.containsKey(conversationId)) {
      return _sharedSecrets[conversationId];
    }
    try {
      final groupKey = await _tryGroupKey(conversationId);
      if (groupKey != null) return groupKey;
      final token = _token;
      final conversations = await _messaging.listConversations(token);
      final match =
          conversations.where((c) => c.id == conversationId).firstOrNull;
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

  Future<DoubleRatchetSession?> _sessionForSending(
      String conversationId) async {
    if (_sessions.containsKey(conversationId)) {
      return _sessions[conversationId]!;
    }
    try {
      final stored = await _sessionStore.load(conversationId);
      if (stored != null) {
        _sessions[conversationId] = stored;
        return stored;
      }
      final token = _token;
      final conversations = await _messaging.listConversations(token);
      final match =
          conversations.where((c) => c.id == conversationId).firstOrNull;
      if (match == null) return null;
      final other = match.participants
          .where((p) => p.userId != _currentUserId)
          .firstOrNull;
      if (other == null) return null;
      final pubKey = await _identity.getExchangeKey(token, other.userId);
      if (pubKey.isEmpty) return null;
      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      final session =
          await DoubleRatchet.initSender(sharedSecret, base64Decode(pubKey));
      _sessions[conversationId] = session;
      await _sessionStore.save(conversationId, session);
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<DoubleRatchetSession?> _sessionForReceiving(
      String conversationId, String senderId) async {
    if (_sessions.containsKey(conversationId)) {
      return _sessions[conversationId]!;
    }
    try {
      final stored = await _sessionStore.load(conversationId);
      if (stored != null) {
        _sessions[conversationId] = stored;
        return stored;
      }
      final token = _token;
      final pubKey = await _identity.getExchangeKey(token, senderId);
      if (pubKey.isEmpty) return null;
      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      final selfKeyPair = await _crypto.loadX25519KeyPair();
      final session =
          await DoubleRatchet.initReceiver(sharedSecret, selfKeyPair);
      _sessions[conversationId] = session;
      await _sessionStore.save(conversationId, session);
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<String> _encryptForConversation(
      String conversationId, String plaintext) async {
    final groupSecret = await _tryGroupKey(conversationId);
    if (groupSecret != null) {
      return await _crypto.encryptWithSharedKey(plaintext, groupSecret);
    }
    final session = await _sessionForSending(conversationId);
    if (session != null) {
      final envelope = await DoubleRatchet.encrypt(session, plaintext);
      await _sessionStore.save(conversationId, session);
      return envelope.encode();
    }
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      return await _crypto.encryptWithSharedKey(plaintext, secret);
    }
    return plaintext;
  }

  Future<String> _decryptCiphertext(
      String conversationId, String ciphertext, String senderId) async {
    if (ciphertext.startsWith('{') && senderId.isNotEmpty) {
      try {
        final session = await _sessionForReceiving(conversationId, senderId);
        if (session != null) {
          final envelope = RatchetEnvelope.decode(ciphertext);
          final plaintext = await DoubleRatchet.decrypt(session, envelope);
          await _sessionStore.save(conversationId, session);
          return plaintext;
        }
      } catch (_) {}
    }
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      try {
        return await _crypto.decryptWithSharedKey(ciphertext, secret);
      } catch (_) {}
    }
    return ciphertext;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final token = _token;
    try {
      final infos = await _messaging.listMessages(token, conversationId);
      final results = <Message>[];
      for (final info in infos) {
        final content = await _decryptCiphertext(
            conversationId, info.ciphertext, info.senderId);
        results.add(_mapMessageInfo(info, content: content));
      }
      await _cache.cacheMessages(conversationId, results);
      return results;
    } catch (_) {
      final cached = await _cache.getCachedMessages(conversationId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<bool> sendMessage(String conversationId, String plaintext) async {
    try {
      final token = _token;
      final ciphertext =
          await _encryptForConversation(conversationId, plaintext);
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
      final match =
          conversations.where((c) => c.id == conversationId).firstOrNull;
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
          final senderId = data['sender_id'] as String? ?? '';
          final content = await _decryptCiphertext(
              conversationId, ciphertext, senderId);
          final message = Message(
            id: data['id'] as String? ?? '',
            senderId: senderId,
            senderName: _resolveSenderName(senderId),
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
    final stillPending = <PendingMessage>[];
    for (final msg in pending) {
      try {
        final ciphertext =
            await _encryptForConversation(conversationId, msg.plaintext);
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
