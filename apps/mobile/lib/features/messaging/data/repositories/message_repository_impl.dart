import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../services/crypto_service.dart';
import '../../../../services/double_ratchet.dart';
import '../../../../services/identity_service.dart';
import '../../../../services/messaging_service.dart';
import '../../../../services/ratchet_session_store.dart';
import '../../../../services/websocket_service.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/entities/conversation_event.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

/// Implementation of [MessageRepository] with Double Ratchet encryption.
///
/// Wires together:
/// - [MessageRemoteDataSource] for API calls
/// - [WebSocketService] for real-time events
/// - [CryptoService] + [IdentityService] + [DoubleRatchet] for encryption
/// - [RatchetSessionStore] for persistent ratchet state
///
/// Architecture flow:
///   UI → Provider → MessageRepositoryImpl → RemoteDataSource / WebSocket
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final WebSocketService _wsService;
  final CryptoService _crypto;
  final IdentityService _identity;
  final MessagingService _messaging;
  final String? Function() _tokenProvider;
  final String? Function() _userIdProvider;
  final RatchetSessionStore _sessionStore;

  // Cached participant names for sender resolution
  final Map<String, String> _participantNames = {};

  // Separate send and receive session caches to prevent state collision.
  // The Double Ratchet can process both directions from the same session,
  // but using two independent sessions avoids subtle state corruption
  // when send and receive interleave.
  final Map<String, DoubleRatchetSession> _sendSessions = {};
  final Map<String, DoubleRatchetSession> _recvSessions = {};

  // Shared secret cache (fallback when DR isn't available yet)
  final Map<String, List<int>> _sharedSecrets = {};

  // Track plaintexts of messages sent by the current user (messageId -> plaintext)
  // so we can display them without needing to decrypt via Double Ratchet.
  final Map<String, Map<String, String>> _sentMessagePlaintexts = {};

  // Stream controllers
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<ConversationEvent>> _eventControllers = {};
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  // WebSocket subscription
  StreamSubscription<WsEvent>? _wsSub;

  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required WebSocketService wsService,
    required CryptoService crypto,
    required IdentityService identity,
    required MessagingService messaging,
    required String? Function() tokenProvider,
    required String? Function() userIdProvider,
    RatchetSessionStore? sessionStore,
  })  : _remoteDataSource = remoteDataSource,
        _wsService = wsService,
        _crypto = crypto,
        _identity = identity,
        _messaging = messaging,
        _tokenProvider = tokenProvider,
        _userIdProvider = userIdProvider,
        _sessionStore = sessionStore ?? RatchetSessionStore() {
    _initWsListener();
  }

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

  // ─── WebSocket Listener ────────────────────────────────────────

  void _initWsListener() {
    _wsSub?.cancel();
    _wsSub = _wsService.eventStream.listen((event) {
      _handleWsEvent(event);
    });

    // Forward connection state changes
    _wsService.stateStream.listen((state) {
      ConnectionState mapped;
      switch (state) {
        case WsConnectionState.disconnected:
          mapped = ConnectionState.disconnected;
        case WsConnectionState.connecting:
          mapped = ConnectionState.connecting;
        case WsConnectionState.connected:
          mapped = ConnectionState.connected;
        case WsConnectionState.failed:
          mapped = ConnectionState.disconnected;
      }
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(mapped);
      }
    });
  }

  void _handleWsEvent(WsEvent event) {
    try {
      final data = event.data as Map<String, dynamic>? ?? {};

      // WebSocketService only defines messageReceived, conversationUpdated, connectionChanged
      if (event.type == WsEventType.messageReceived) {
        _handleMessageReceived(data);
      }
    } catch (e) {
      debugPrint('[MessagingRepo] Error handling WS event: $e');
    }
  }

  void _handleMessageReceived(Map<String, dynamic> data) {
    final conversationId = data['conversation_id'] as String?;
    final senderId = data['sender_id'] as String? ?? '';
    if (conversationId == null || conversationId.isEmpty) return;

    // Don't process own messages from WS (they're already handled via send)
    if (senderId == _currentUserId) return;

    final ciphertext = data['ciphertext'] as String? ?? '';

    _decryptCiphertext(conversationId, ciphertext, senderId).then((content) {
      try {
        final message = Message(
          id: data['id'] as String? ?? '',
          conversationId: conversationId,
          senderId: senderId,
          senderName: _resolveSenderName(senderId),
          content: content,
          createdAt: _tryParseDate(data['created_at'] as String?),
        status: MessageStatus.sent,
      );

        _messageControllers[conversationId]?.add(message);
      } catch (_) {}
    }).catchError((_) {});
  }

  // ─── Participant Resolution ────────────────────────────────────

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
      final participants =
          await _messaging.getParticipants(token, conversationId);
      final other = participants
          .where((p) => p.userId != _currentUserId)
          .firstOrNull;
      if (other != null) return other;
    } catch (_) {}

    return null;
  }

  Future<void> _loadParticipantNames(String conversationId) async {
    if (_participantNames.isNotEmpty) return;
    try {
      final participants =
          await _messaging.getParticipants(_token, conversationId);
      for (final p in participants) {
        _participantNames[p.userId] = p.username;
      }
    } catch (_) {}
  }

  String _resolveSenderName(String senderId) {
    if (senderId == _currentUserId) return 'You';
    return _participantNames[senderId] ?? 'Unknown';
  }

  // ─── Key Management ────────────────────────────────────────────

  /// Ensure our X25519 exchange key is stored on the server.
  /// Safety net for cases where [storeExchangeKey] failed during creation.
  Future<void> _ensureExchangeKeyUploaded() async {
    try {
      final x25519PubKey = await _crypto.getX25519PublicKeyBase64();
      await _identity.storeExchangeKey(_token, x25519PubKey);
    } catch (_) {}
  }

  // ─── Multi-Party Group Key ────────────────────────────────────

  /// Try to obtain a shared group key for multi-party conversations.
  /// Group keys are encrypted by the conversation creator and stored on
  /// the server.  Each participant decrypts it using the creator's X25519
  /// exchange key, giving all members a common AES-GCM secret without
  /// the overhead of per-member Double Ratchet sessions.
  Future<List<int>?> _tryGroupKey(String conversationId) async {
    try {
      await _ensureExchangeKeyUploaded();
      final encryptedKey =
          await _messaging.getGroupKey(_token, conversationId);
      if (encryptedKey.isNotEmpty) {
        // Find the creator (first non-self participant) to get their
        // exchange key for decrypting the group key.
        try {
          final participants =
              await _messaging.getParticipants(_token, conversationId);
          final creator = participants
              .where((p) => p.userId != _currentUserId)
              .firstOrNull;
          if (creator != null) {
            final creatorPubKey =
                await _identity.getExchangeKey(_token, creator.userId);
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

  // ─── Shared Secret (fallback) ──────────────────────────────────

  Future<List<int>?> _ensureSecret(String conversationId) async {
    if (_sharedSecrets.containsKey(conversationId)) {
      return _sharedSecrets[conversationId];
    }
    try {
      // Try the group key first — multi-party conversations use a
      // shared AES-GCM key instead of per-member Double Ratchet.
      final groupKey = await _tryGroupKey(conversationId);
      if (groupKey != null) return groupKey;

      await _ensureExchangeKeyUploaded();
      final other = await _findOtherParticipant(conversationId);
      if (other == null) return null;
      final pubKey =
          await _identity.getExchangeKey(_token, other.userId);
      if (pubKey.isEmpty) return null;
      final secret = await _crypto.deriveSharedSecret(pubKey);
      _sharedSecrets[conversationId] = secret;
      return secret;
    } catch (_) {
      return null;
    }
  }

  // ─── Double Ratchet Session Management ─────────────────────────

  Future<DoubleRatchetSession?> _sessionForSending(
      String conversationId) async {
    debugPrint('[DR.sessionForSending] conv=$conversationId');

    if (_sendSessions.containsKey(conversationId)) {
      return _sendSessions[conversationId]!;
    }

    // Cross-check: reuse receiver session if it has a sending chain key.
    if (_recvSessions.containsKey(conversationId) &&
        _recvSessions[conversationId]!.sendingChainKey != null) {
      _sendSessions[conversationId] = _recvSessions[conversationId]!;
      return _sendSessions[conversationId]!;
    }

    try {
      final stored = await _sessionStore.loadSend(conversationId);
      if (stored != null) {
        _sendSessions[conversationId] = stored;
        return stored;
      }

      // Persistence cross-check: load receiver session from store.
      final recvStored = await _sessionStore.loadRecv(conversationId);
      if (recvStored != null && recvStored.sendingChainKey != null) {
        _sendSessions[conversationId] = recvStored;
        _recvSessions[conversationId] = recvStored;
        return recvStored;
      }

      debugPrint('[DR.sessionForSending]  no existing session — creating initSender...');

      await _ensureExchangeKeyUploaded();

      final other = await _findOtherParticipant(conversationId);
      if (other == null) {
        debugPrint('[DR.sessionForSending]  no other participant found');
        return null;
      }

      final pubKey =
          await _identity.getExchangeKey(_token, other.userId);
      if (pubKey.isEmpty) {
        debugPrint('[DR.sessionForSending]  getExchangeKey returned EMPTY');
        return null;
      }

      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      final session =
          await DoubleRatchet.initSender(sharedSecret, base64Decode(pubKey));

      _sendSessions[conversationId] = session;
      await _sessionStore.saveSend(conversationId, session);
      return session;
    } catch (e, st) {
      debugPrint('[DR.sessionForSending]  EXCEPTION: $e\n$st');
      return null;
    }
  }

  Future<String?> _resolveTargetId(
      String conversationId, String senderId) async {
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
      return _recvSessions[conversationId]!;
    }

    // Cross-check: reuse sender session.
    if (_sendSessions.containsKey(conversationId)) {
      _recvSessions[conversationId] = _sendSessions[conversationId]!;
      return _recvSessions[conversationId]!;
    }

    try {
      final stored = await _sessionStore.loadRecv(conversationId);
      if (stored != null) {
        _recvSessions[conversationId] = stored;
        return stored;
      }

      final sendStored = await _sessionStore.loadSend(conversationId);
      if (sendStored != null) {
        _recvSessions[conversationId] = sendStored;
        _sendSessions[conversationId] = sendStored;
        return sendStored;
      }

      debugPrint('[DR.sessionForReceiving]  no existing session — creating initReceiver...');

      final targetId = await _resolveTargetId(conversationId, senderId);
      if (targetId == null) return null;

      await _ensureExchangeKeyUploaded();

      final pubKey =
          await _identity.getExchangeKey(_token, targetId);
      if (pubKey.isEmpty) {
        debugPrint('[DR.sessionForReceiving]  getExchangeKey returned EMPTY');
        return null;
      }

      final sharedSecret = await _crypto.deriveSharedSecret(pubKey);
      final selfKeyPair = await _crypto.loadX25519KeyPair();
      final session =
          await DoubleRatchet.initReceiver(sharedSecret, selfKeyPair);

      _recvSessions[conversationId] = session;
      await _sessionStore.saveRecv(conversationId, session);
      return session;
    } catch (e, st) {
      debugPrint('[DR.sessionForReceiving]  EXCEPTION: $e\n$st');
      return null;
    }
  }

  // ─── Encryption / Decryption ───────────────────────────────────

  /// Encrypt plaintext for sending to a conversation.
  /// Priority order:
  ///   1. Shared group key (multi-party conversations)
  ///   2. Double Ratchet (1:1 conversations)
  ///   3. Shared-secret AES-GCM (fallback for 1:1)
  ///   4. Plaintext (last resort, should not happen in production)
  Future<String> _encryptForConversation(
      String conversationId, String plaintext) async {
    // Multi-party: try group key first (shared AES-GCM, no DR overhead).
    final groupSecret = await _tryGroupKey(conversationId);
    if (groupSecret != null) {
      return await _crypto.encryptWithSharedKey(plaintext, groupSecret);
    }
    // 1:1: use Double Ratchet if a session exists.
    final session = await _sessionForSending(conversationId);
    if (session != null) {
      final envelope = await DoubleRatchet.encrypt(session, plaintext);
      await _sessionStore.saveSend(conversationId, session);
      return envelope.encode();
    }
    // Fallback: shared-secret AES-GCM
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      return await _crypto.encryptWithSharedKey(plaintext, secret);
    }
    // Last resort: send plaintext (should not happen in production)
    debugPrint('[MessagingRepo] WARNING: sending plaintext (no encryption available)');
    return plaintext;
  }

  /// Decrypt a ciphertext received from another user.
  /// Uses Double Ratchet if the ciphertext is a JSON envelope,
  /// falling back to shared-secret AES-GCM.
  Future<String> _decryptCiphertext(
      String conversationId, String ciphertext, String senderId) async {
    if (ciphertext.startsWith('{') && senderId.isNotEmpty) {
      try {
        final session =
            await _sessionForReceiving(conversationId, senderId);
        if (session != null) {
          final envelope = RatchetEnvelope.decode(ciphertext);
          final plaintext =
              await DoubleRatchet.decrypt(session, envelope);
          await _sessionStore.saveRecv(conversationId, session);
          return plaintext;
        }
      } catch (e) {
        debugPrint('[MessagingRepo] DR decrypt failed: $e');
      }
    }
    // Fallback: shared-secret AES-GCM
    final secret = await _ensureSecret(conversationId);
    if (secret != null) {
      try {
        return await _crypto.decryptWithSharedKey(ciphertext, secret);
      } catch (e) {
        debugPrint('[MessagingRepo] shared-secret decrypt failed: $e');
      }
    }
    return ciphertext;
  }

  /// Resolve the plaintext for a message sent by the current user.
  /// Own messages are encrypted via Double Ratchet, but the sending chain
  /// state is asymmetric — the sender cannot decrypt them back.
  /// We store plaintexts in memory during [sendMessage] and look them up here.
  String _resolveOwnMessagePlaintext(
      String conversationId, String messageId, String defaultContent) {
    final byConv = _sentMessagePlaintexts[conversationId];
    if (byConv != null) {
      final cached = byConv[messageId];
      if (cached != null) return cached;
    }
    return defaultContent;
  }

  // ─── MessageRepository Implementation ──────────────────────────

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String plaintext,
    required String currentUserId,
    required String currentUserName,
  }) async {
    try {
      final ciphertext =
          await _encryptForConversation(conversationId, plaintext);
      final dto = await _remoteDataSource.sendMessage(
        token: _token,
        conversationId: conversationId,
        ciphertext: ciphertext,
      );

      // Store plaintext for own-message resolution
      _sentMessagePlaintexts
          .putIfAbsent(conversationId, () => {})
          [dto.id] = plaintext;

      final message = Message(
        id: dto.id,
        conversationId: conversationId,
        senderId: currentUserId,
        senderName: currentUserName,
        content: plaintext,
        createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
        status: MessageStatus.sent,
      );

      _messageControllers[conversationId]?.add(message);
      return message;
    } catch (e) {
      debugPrint('[MessagingRepo] sendMessage failed: $e');
      return Message(
        id: '',
        conversationId: conversationId,
        senderId: currentUserId,
        senderName: currentUserName,
        content: plaintext,
        createdAt: DateTime.now(),
        status: MessageStatus.failed,
      );
    }
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final dtos = await _remoteDataSource.listMessages(
        token: _token,
        conversationId: conversationId,
      );

      await _loadParticipantNames(conversationId);

      final messages = <Message>[];
      for (final dto in dtos) {
        final isOwn = dto.senderId == _currentUserId;
        final content = isOwn
            ? _resolveOwnMessagePlaintext(conversationId, dto.id, dto.ciphertext)
            : await _decryptCiphertext(
                conversationId, dto.ciphertext, dto.senderId);

        messages.add(Message(
          id: dto.id,
          conversationId: conversationId,
          senderId: dto.senderId,
          senderName: isOwn ? 'You' : _resolveSenderName(dto.senderId),
          content: content,
          createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
          status: MessageStatus.sent,
        ));
      }

      return messages;
    } catch (e) {
      debugPrint('[MessagingRepo] getMessages failed: $e');
      rethrow;
    }
  }

  @override
  Stream<Message> observeMessages(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] =
          StreamController<Message>.broadcast();
    }
    return _messageControllers[conversationId]!.stream;
  }

  @override
  Stream<ConversationEvent> observeEvents(String conversationId) {
    if (!_eventControllers.containsKey(conversationId)) {
      _eventControllers[conversationId] =
          StreamController<ConversationEvent>.broadcast();
    }
    return _eventControllers[conversationId]!.stream;
  }

  @override
  Stream<ConnectionState> observeConnectionState() {
    return _connectionStateController.stream;
  }

  @override
  Future<Message> retryMessage(
    String conversationId,
    Message failedMessage,
  ) async {
    return sendMessage(
      conversationId: conversationId,
      plaintext: failedMessage.content,
      currentUserId: failedMessage.senderId,
      currentUserName: failedMessage.senderName,
    );
  }

  @override
  Future<void> failPendingMessages(String conversationId) async {
    if (conversationId.isEmpty) return;
    _messageControllers[conversationId]?.add(
      Message(
        id: '',
        conversationId: conversationId,
        senderId: _currentUserId,
        senderName: 'You',
        content: 'Message could not be sent.',
        createdAt: DateTime.now(),
        status: MessageStatus.failed,
      ),
    );
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await _wsSub?.cancel();
    for (final ctrl in _messageControllers.values) {
      await ctrl.close();
    }
    for (final ctrl in _eventControllers.values) {
      await ctrl.close();
    }
    await _connectionStateController.close();
  }

  // ─── Helpers ───────────────────────────────────────────────────

  DateTime _tryParseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
