import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
  // Separate send and receive session caches to prevent state collision.
  // The Double Ratchet can process both directions from the same session,
  // but using two independent sessions avoids subtle state corruption
  // when send and receive interleave (e.g., sendMessage followed by
  // getMessages which needs to decrypt the other user's reply).
  final Map<String, DoubleRatchetSession> _sendSessions = {};
  final Map<String, DoubleRatchetSession> _recvSessions = {};
  final Map<String, String> _participantNames = {};
  // Track plaintexts of messages sent by the current user (messageId -> plaintext)
  // so we can display them without needing to decrypt via Double Ratchet.
  final Map<String, Map<String, String>> _sentMessagePlaintexts = {};
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

  /// Find the other participant in a conversation.
  /// Tries [listConversations] first (fast, cached), then falls back
  /// to the dedicated [getParticipants] endpoint if the other user
  /// isn't found — this handles cases where the conversation list
  /// response has incomplete participant data.
  Future<ParticipantInfo?> _findOtherParticipant(
      String conversationId) async {
    final token = _token;
    try {
      // Fast path: check the conversation list response.
      final conversations = await _messaging.listConversations(token);
      final match =
          conversations.where((c) => c.id == conversationId).firstOrNull;
      if (match != null) {
        final other = match.participants
            .where((p) => p.userId != _currentUserId)
            .firstOrNull;
        if (other != null) return other;
      }
    } catch (_) {
      // Fall through to the dedicated endpoint.
    }

    // Fallback: fetch participants directly via the dedicated API.
    try {
      final participants = await _messaging.getParticipants(token, conversationId);
      debugPrint('[DR.findOther] getParticipants returned ${participants.length} participants: '
          '${participants.map((p) => "${p.userId.substring(0, 8)}.../${p.username}").join(", ")}');
      debugPrint('[DR.findOther] currentUserId=${_currentUserId.substring(0, 8)}...');
      final other = participants
          .where((p) => p.userId != _currentUserId)
          .firstOrNull;
      if (other != null) return other;
      debugPrint('[DR.findOther] no non-self participant found in getParticipants result');
    } catch (e) {
      debugPrint('[DR.findOther] getParticipants threw: $e');
    }

    return null;
  }

  /// Load participant names for a conversation into [_participantNames].
  Future<void> _loadParticipantNames(String conversationId) async {
    if (_participantNames.isNotEmpty) return;
    try {
      final token = _token;
      final participants =
          await _messaging.getParticipants(token, conversationId);
      for (final p in participants) {
        _participantNames[p.userId] = p.username;
      }
    } catch (_) {}
  }

  /// Ensure our X25519 exchange key is stored on the server.
  /// This is a safety net for cases where [storeExchangeKey] failed
  /// during identity creation.  Called before every key-dependent
  /// operation so stale registrations self-heal.
  Future<void> _ensureExchangeKeyUploaded() async {
    try {
      final token = _token;
      final x25519PubKey = await _crypto.getX25519PublicKeyBase64();
      await _identity.storeExchangeKey(token, x25519PubKey);
    } catch (_) {
      // Best-effort — if upload fails we fall through to existing
      // error paths (getExchangeKey returns empty → null session).
    }
  }

  Future<List<int>?> _tryGroupKey(String conversationId) async {
    try {
      final token = _token;
      await _ensureExchangeKeyUploaded();
      final encryptedKey =
          await _messaging.getGroupKey(token, conversationId);
      if (encryptedKey.isNotEmpty) {
        // Group keys are encrypted by the creator. We need the creator's
        // exchange key to decrypt it. Use getParticipants to find who
        // created this conversation.
        try {
          final participants =
              await _messaging.getParticipants(token, conversationId);
          final creator = participants
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
        } catch (_) {}
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

      // Safety net: re-upload our exchange key in case it was missed.
      await _ensureExchangeKeyUploaded();

      final other = await _findOtherParticipant(conversationId);
      if (other == null) return null;
      final token = _token;
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
    debugPrint('[DR.sessionForSending] conv=$conversationId');
    if (_sendSessions.containsKey(conversationId)) {
      debugPrint('[DR.sessionForSending]  FOUND in send memory cache');
      return _sendSessions[conversationId]!;
    }
    // Cross-check: a session created via _sessionForReceiving (initReceiver + DH
    // ratchet) already has a sending chain key.  Reuse it for sending replies.
    // Guard against sessions that haven't completed the DH ratchet yet (no
    // sending chain key), which would cause [DoubleRatchet.encrypt] to throw.
    if (_recvSessions.containsKey(conversationId) &&
        _recvSessions[conversationId]!.sendingChainKey != null) {
      debugPrint('[DR.sessionForSending]  FOUND in recv memory cache — reusing');
      _sendSessions[conversationId] = _recvSessions[conversationId]!;
      return _sendSessions[conversationId]!;
    }
    try {
      final stored = await _sessionStore.loadSend(conversationId);
      if (stored != null) {
        debugPrint('[DR.sessionForSending]  loaded from persistent store');
        _sendSessions[conversationId] = stored;
        return stored;
      }
      // Persistence cross-check: load the receiver session if no sender session.
      // Only reuse if it has a sending chain key (i.e., it completed the DH
      // ratchet).  Bare initReceiver sessions cannot encrypt.
      final recvStored = await _sessionStore.loadRecv(conversationId);
      if (recvStored != null && recvStored.sendingChainKey != null) {
        debugPrint('[DR.sessionForSending]  loaded recv session from store — reusing');
        _sendSessions[conversationId] = recvStored;
        _recvSessions[conversationId] = recvStored;
        return recvStored;
      }
      debugPrint('[DR.sessionForSending]  no existing session — creating initSender...');

      // Ensure our key is on the server before fetching the other
      // user's key — if our key was missing, the other user would
      // not be able to decrypt our messages.
      await _ensureExchangeKeyUploaded();

      final other = await _findOtherParticipant(conversationId);
      if (other == null) {
        debugPrint('[DR.sessionForSending]  no other participant found');
        return null;
      }
      final token = _token;
      final pubKey = await _identity.getExchangeKey(token, other.userId);
      if (pubKey.isEmpty) {
        debugPrint('[DR.sessionForSending]  getExchangeKey returned EMPTY');
        return null;
      }
      debugPrint('[DR.sessionForSending]  otherPubKey (first 16): ${pubKey.substring(0, pubKey.length > 16 ? 16 : pubKey.length)}');
      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      debugPrint('[DR.sessionForSending]  sharedSecret derived (${sharedSecret.length} bytes)');
      final session =
          await DoubleRatchet.initSender(sharedSecret, base64Decode(pubKey));
      debugPrint('[DR.sessionForSending]  initSender created');
      _sendSessions[conversationId] = session;
      await _sessionStore.saveSend(conversationId, session);
      return session;
    } catch (e, st) {
      debugPrint('[DR.sessionForSending]  EXCEPTION: $e');
      debugPrint('[DR.sessionForSending]  stack: $st');
      return null;
    }
  }

  /// Resolve the correct exchange-key target for a receiving session.
  /// When [senderId] is the current user, we must use the OTHER participant's
  /// key, otherwise the shared secret degrades to DH(my_private, my_public).
  Future<String?> _resolveTargetId(String conversationId, String senderId) async {
    if (senderId != _currentUserId) return senderId;
    try {
      final other = await _findOtherParticipant(conversationId);
      return other?.userId;
    } catch (_) {
      return null;
    }
  }

  Future<DoubleRatchetSession?> _sessionForReceiving(
      String conversationId, String senderId) async {
    debugPrint('[DR.sessionForReceiving] conv=$conversationId sender=$senderId');
    if (_recvSessions.containsKey(conversationId)) {
      debugPrint('[DR.sessionForReceiving]  FOUND in recv memory cache');
      return _recvSessions[conversationId]!;
    }
    // Cross-check: a session created via _sessionForSending (initSender) can also
    // receive after a DH ratchet step.  Reuse it for decrypting the other user's
    // messages.
    if (_sendSessions.containsKey(conversationId)) {
      debugPrint('[DR.sessionForReceiving]  FOUND in send memory cache — reusing');
      _recvSessions[conversationId] = _sendSessions[conversationId]!;
      return _recvSessions[conversationId]!;
    }
    try {
      final stored = await _sessionStore.loadRecv(conversationId);
      if (stored != null) {
        debugPrint('[DR.sessionForReceiving]  loaded from persistent store');
        _recvSessions[conversationId] = stored;
        return stored;
      }
      // Persistence cross-check: load the sender session if no receiver session.
      final sendStored = await _sessionStore.loadSend(conversationId);
      if (sendStored != null) {
        debugPrint('[DR.sessionForReceiving]  loaded send session from store — reusing');
        _recvSessions[conversationId] = sendStored;
        _sendSessions[conversationId] = sendStored;
        return sendStored;
      }
      debugPrint('[DR.sessionForReceiving]  no existing session — creating initReceiver...');
      final targetId = await _resolveTargetId(conversationId, senderId);
      if (targetId == null) {
        debugPrint('[DR.sessionForReceiving]  _resolveTargetId returned NULL');
        return null;
      }
      final token = _token;

      // Re-upload our exchange key so the other user can decrypt
      // our messages.  This handles the case where identity creation
      // succeeded but the key upload silently failed.
      await _ensureExchangeKeyUploaded();

      final pubKey = await _identity.getExchangeKey(token, targetId);
      if (pubKey.isEmpty) {
        debugPrint('[DR.sessionForReceiving]  getExchangeKey returned EMPTY for target=$targetId');
        return null;
      }
      debugPrint('[DR.sessionForReceiving]  pubKey (first 16 chars): ${pubKey.substring(0, pubKey.length > 16 ? 16 : pubKey.length)}');
      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      debugPrint('[DR.sessionForReceiving]  sharedSecret derived (${sharedSecret.length} bytes)');
      final selfKeyPair = await _crypto.loadX25519KeyPair();
      debugPrint('[DR.sessionForReceiving]  selfKeyPair loaded: pub=${base64Encode(selfKeyPair.publicKey.bytes).substring(0, 16)}');
      final session =
          await DoubleRatchet.initReceiver(sharedSecret, selfKeyPair);
      debugPrint('[DR.sessionForReceiving]  initReceiver session created');
      _recvSessions[conversationId] = session;
      await _sessionStore.saveRecv(conversationId, session);
      return session;
    } catch (e, st) {
      debugPrint('[DR.sessionForReceiving]  EXCEPTION: $e');
      debugPrint('[DR.sessionForReceiving]  stack: $st');
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
      await _sessionStore.saveSend(conversationId, session);
      return envelope.encode();
    }
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      return await _crypto.encryptWithSharedKey(plaintext, secret);
    }
    return plaintext;
  }

  /// Decrypt a message received from another user (not self).
  /// Uses Double Ratchet if the ciphertext is a JSON envelope, falling back
  /// to shared-secret AES-GCM decryption.
  Future<String> _decryptCiphertext(
      String conversationId, String ciphertext, String senderId) async {
    debugPrint('[DR] _decryptCiphertext: conv=$conversationId sender=$senderId');
    debugPrint('[DR]   ciphertext startsWith "{" = ${ciphertext.startsWith('{')}');
    debugPrint('[DR]   ciphertext preview: ${ciphertext.length > 80 ? ciphertext.substring(0, 80) : ciphertext}');
    if (ciphertext.startsWith('{') && senderId.isNotEmpty) {
      try {
        final session = await _sessionForReceiving(conversationId, senderId);
        if (session != null) {
          debugPrint('[DR]   session obtained, attempting decrypt...');
          debugPrint('[DR]   session state: dhRemote=${session.dhRemote != null ? base64Encode(session.dhRemote!).substring(0, 16) : "null"}, '
              'recvCount=${session.receiveCount}, sendCount=${session.sendCount}');
          final envelope = RatchetEnvelope.decode(ciphertext);
          debugPrint('[DR]   envelope: h.n=${envelope.header.messageNumber}, h.pn=${envelope.header.previousChainLength}');
          final plaintext = await DoubleRatchet.decrypt(session, envelope);
          debugPrint('[DR]   decrypt SUCCEEDED: "$plaintext"');
          await _sessionStore.saveRecv(conversationId, session);
          return plaintext;
        } else {
          debugPrint('[DR]   _sessionForReceiving returned NULL');
        }
      } catch (e, st) {
        debugPrint('[DR]   decrypt THREW: $e');
        debugPrint('[DR]   stack: $st');
      }
    } else {
      debugPrint('[DR]   SKIP double-ratchet path (not JSON or empty sender)');
    }
    debugPrint('[DR]   falling back to shared-secret path...');
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      try {
        final result = await _crypto.decryptWithSharedKey(ciphertext, secret);
        debugPrint('[DR]   shared-secret decrypt SUCCEEDED');
        return result;
      } catch (e) {
        debugPrint('[DR]   shared-secret decrypt threw: $e');
      }
    } else {
      debugPrint('[DR]   _ensureSecret returned NULL');
    }
    debugPrint('[DR]   FINAL: returning raw ciphertext');
    return ciphertext;
  }

  /// Resolve the plaintext for a message sent by the current user.
  /// Own messages are encrypted via Double Ratchet, but the sending chain
  /// state is asymmetric – the sender cannot decrypt them back that way.
  /// We therefore store plaintexts in memory during [sendMessage] and look
  /// them up here.  Falls back to [ciphertext] when nothing is found.
  Future<String> _resolveOwnMessagePlaintext(
    String conversationId,
    String messageId,
    String ciphertext,
  ) async {
    // 1. Try in-memory map populated during sendMessage.
    final byConv = _sentMessagePlaintexts[conversationId];
    if (byConv != null) {
      final cached = byConv[messageId];
      if (cached != null) return cached;
    }
    // 2. Try the persistence cache.
    try {
      final cached = await _cache.getCachedMessages(conversationId);
      if (cached != null) {
        final match = cached.where((m) => m.id == messageId).firstOrNull;
        if (match != null) return match.content;
      }
    } catch (_) {}
    // 3. Fall back – show the ciphertext rather than crash.
    return ciphertext;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final token = _token;
    try {
      await _loadParticipantNames(conversationId);

      // Cache-first approach: DO NOT delete the Double Ratchet session.
      // The session tracks both sending and receiving chain state, and
      // deleting it would force a fresh initSender on the next send,
      // which uses the OTHER user's IDENTITY key as dhRemote. The other
      // user's session has already evolved past the identity key via a
      // DH ratchet step (now using ephemeral keys), so the DH shared
      // secrets would NOT match, and decryption would produce gibberish.
      //
      // Instead, use the message cache: if we have cached messages,
      // only fetch and decrypt NEW messages from the API. This avoids
      // re-decrypting old messages whose counters (receiveCount,
      // receivingChainKey) have already advanced past them.
      final cached = await _cache.getCachedMessages(conversationId);
      if (cached != null && cached.isNotEmpty) {
        final infos = await _messaging.listMessages(token, conversationId);
        if (infos.length <= cached.length) {
          // No new messages on the server — return cache directly, but
          // re-resolve sender names in case the user context changed
          // (e.g. login/logout between sessions).
          return cached.map((m) => Message(
            id: m.id,
            senderId: m.senderId,
            senderName: _resolveSenderName(m.senderId),
            content: m.content,
            createdAt: m.createdAt,
            status: m.status,
          )).toList();
        }
        // New messages exist — only decrypt the delta.
        final newInfos = infos.sublist(cached.length);
        final newMessages = <Message>[];
        for (final info in newInfos) {
          final content =
              await _decryptSingleMessage(conversationId, info);
          newMessages.add(_mapMessageInfo(info, content: content));
        }
        final allMessages = [...cached, ...newMessages];
        await _cache.cacheMessages(conversationId, allMessages);
        return allMessages;
      }

      // No cache available — full fetch-and-decrypt.  The session is
      // either fresh (first call) or has been reset by the conversation
      // lifecycle.  Either way there are no previously-decrypted
      // messages to worry about.
      final infos = await _messaging.listMessages(token, conversationId);
      final results = <Message>[];
      for (final info in infos) {
        final content =
            await _decryptSingleMessage(conversationId, info);
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

  /// Decrypt a single message, handling own-message resolution vs.
  /// cross-user decryption via Double Ratchet / shared-secret fallback.
  Future<String> _decryptSingleMessage(
    String conversationId,
    MessageInfo info,
  ) async {
    if (info.senderId == _currentUserId) {
      return _resolveOwnMessagePlaintext(
        conversationId,
        info.id,
        info.ciphertext,
      );
    }
    return _decryptCiphertext(
      conversationId,
      info.ciphertext,
      info.senderId,
    );
  }

  @override
  Future<bool> sendMessage(String conversationId, String plaintext) async {
    try {
      final token = _token;
      final ciphertext =
          await _encryptForConversation(conversationId, plaintext);
      final info =
          await _messaging.sendMessage(token, conversationId, ciphertext);
      // Keep the plaintext so we can show it back to the current user later.
      _sentMessagePlaintexts
          .putIfAbsent(conversationId, () => {})
          [info.id] = plaintext;
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

    _loadParticipantNames(conversationId);

    _wsSub?.cancel();
    _wsSub = _ws.eventStream.listen((event) async {
      if (event.type == WsEventType.messageReceived && event.data is Map) {
        final data = event.data as Map<String, dynamic>;
        final msgConvId = data['conversation_id'] as String?;
        final senderId = data['sender_id'] as String? ?? '';
        if (msgConvId == conversationId && senderId != _currentUserId) {
          final ciphertext = data['ciphertext'] as String? ?? '';
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
    if (senderId == _currentUserId) {
      debugPrint('[MSG] _resolveSenderName: senderId=$senderId matches currentUser — returning "You"');
      return 'You';
    }
    final name = _participantNames[senderId];
    final uidPreview = _currentUserId.length > 8
        ? _currentUserId.substring(0, 8)
        : _currentUserId;
    debugPrint('[MSG] _resolveSenderName: senderId=$senderId != currentUser=$uidPreview → '
        'name="${name ?? "Unknown"}"');
    return name ?? 'Unknown';
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
