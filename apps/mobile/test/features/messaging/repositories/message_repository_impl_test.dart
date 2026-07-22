import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:hush_mobile/features/messaging/data/models/message_dto.dart';
import 'package:hush_mobile/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message_status.dart';
import 'package:hush_mobile/features/messaging/domain/entities/connection_state.dart' as domain;
import 'package:hush_mobile/services/crypto_service.dart';
import 'package:hush_mobile/services/double_ratchet.dart';
import 'package:hush_mobile/services/identity_service.dart';
import 'package:hush_mobile/services/messaging_service.dart';
import 'package:hush_mobile/services/ratchet_session_store.dart';
import 'package:hush_mobile/services/websocket_service.dart';
import 'package:hush_mobile/services/api_client.dart';

// ═══════════════════════════════════════════════════════════════
// Fake API Client (needed by MessagingService constructor)
// ═══════════════════════════════════════════════════════════════

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://test');
}

// ═══════════════════════════════════════════════════════════════
// Fake Ratchet Session Store (avoids FlutterSecureStorage in tests)
// ═══════════════════════════════════════════════════════════════

class _FakeRatchetSessionStore extends RatchetSessionStore {
  final Map<String, DoubleRatchetSession> _store = {};

  _FakeRatchetSessionStore() : super();

  @override
  Future<DoubleRatchetSession?> loadSend(String conversationId) async {
    return _store['send:$conversationId'];
  }

  @override
  Future<void> saveSend(
      String conversationId, DoubleRatchetSession session) async {
    _store['send:$conversationId'] = session;
  }

  @override
  Future<DoubleRatchetSession?> loadRecv(String conversationId) async {
    return _store['recv:$conversationId'];
  }

  @override
  Future<void> saveRecv(
      String conversationId, DoubleRatchetSession session) async {
    _store['recv:$conversationId'] = session;
  }

  @override
  Future<void> delete(String conversationId) async {
    _store.remove('send:$conversationId');
    _store.remove('recv:$conversationId');
  }
}

// ═══════════════════════════════════════════════════════════════
// Mock Remote Data Source
// ═══════════════════════════════════════════════════════════════

class MockRemoteDataSource extends MessageRemoteDataSource {
  int sendCallCount = 0;
  int listCallCount = 0;
  bool shouldThrowOnSend = false;
  bool shouldThrowOnList = false;

  final messagesToReturn = <MessageDto>[];

  MockRemoteDataSource()
      : super(messaging: MessagingService(api: _FakeApiClient()));

  @override
  Future<MessageDto> sendMessage({
    required String token,
    required String conversationId,
    required String ciphertext,
  }) async {
    sendCallCount++;
    if (shouldThrowOnSend) throw Exception('Send failed');
    return MessageDto(
      id: 'sent-msg-1',
      conversationId: conversationId,
      senderId: 'user-2',
      senderName: '',
      ciphertext: ciphertext,
      createdAt: DateTime.now().toIso8601String(),
      status: 'sent',
    );
  }

  @override
  Future<List<MessageDto>> listMessages({
    required String token,
    required String conversationId,
  }) async {
    listCallCount++;
    if (shouldThrowOnList) throw Exception('List failed');
    return messagesToReturn;
  }
}

// ═══════════════════════════════════════════════════════════════
// Mock WebSocket Service
// ═══════════════════════════════════════════════════════════════

class MockWebSocketService extends WebSocketService {
  final _eventController = StreamController<WsEvent>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  @override
  Stream<WsEvent> get eventStream => _eventController.stream;

  @override
  Stream<WsConnectionState> get stateStream => _stateController.stream;

  void emitEvent(WsEvent event) => _eventController.add(event);
  void emitState(WsConnectionState state) => _stateController.add(state);

  @override
  Future<void> dispose() async {
    await _eventController.close();
    await _stateController.close();
  }
}

// ═══════════════════════════════════════════════════════════════
// Mock Crypto Service with DR support
// ═══════════════════════════════════════════════════════════════

class MockCryptoService extends CryptoService {
  int deriveCallCount = 0;
  int encryptSharedCallCount = 0;
  int decryptSharedCallCount = 0;

  MockCryptoService() : super();

  @override
  Future<List<int>> deriveSharedSecret(String otherPublicKeyBase64) async {
    deriveCallCount++;
    return List<int>.generate(32, (i) => i);
  }

  @override
  Future<String> encryptWithSharedKey(
      String plaintext, List<int> sharedSecret) async {
    encryptSharedCallCount++;
    // Return a fake ciphertext that does NOT start with '{' (not DR envelope)
    return base64Encode(utf8.encode('encrypted:$plaintext'));
  }

  @override
  Future<String> decryptWithSharedKey(
      String ciphertext, List<int> sharedSecret) async {
    decryptSharedCallCount++;
    final decoded = utf8.decode(base64Decode(ciphertext));
    if (decoded.startsWith('encrypted:')) {
      return decoded.substring('encrypted:'.length);
    }
    return ciphertext;
  }

  @override
  Future<String> getX25519PublicKeyBase64() async {
    return base64Encode(List<int>.generate(32, (i) => i));
  }

  @override
  Future<SimpleKeyPairData> loadX25519KeyPair() async {
    final x25519 = X25519();
    return await (await x25519.newKeyPair()).extract();
  }
}

// ═══════════════════════════════════════════════════════════════
// Mock Identity Service
// ═══════════════════════════════════════════════════════════════

class MockIdentityService extends IdentityService {
  int getKeyCallCount = 0;
  int storeKeyCallCount = 0;

  MockIdentityService() : super(api: _FakeApiClient());

  @override
  Future<String> getExchangeKey(String token, String userId) async {
    getKeyCallCount++;
    return base64Encode(List<int>.generate(32, (i) => i));
  }

  @override
  Future<void> storeExchangeKey(String token, String x25519PublicKey) async {
    storeKeyCallCount++;
  }
}

// ═══════════════════════════════════════════════════════════════
// Mock MessagingService
// ═══════════════════════════════════════════════════════════════

class MockMessagingService extends MessagingService {
  int participantsCallCount = 0;

  MockMessagingService() : super(api: _FakeApiClient());

  @override
  Future<List<ParticipantInfo>> getParticipants(
      String token, String conversationId) async {
    participantsCallCount++;
    return [
      ParticipantInfo(userId: 'user-2', username: 'Bob'),
    ];
  }

  @override
  Future<String> getGroupKey(String token, String conversationId) async {
    return '';
  }
}

/// MessagingService that returns empty participants list (no other user).
class _EmptyParticipantsMessaging extends MessagingService {
  _EmptyParticipantsMessaging() : super(api: _FakeApiClient());

  @override
  Future<List<ParticipantInfo>> getParticipants(
      String token, String conversationId) async {
    return [];
  }

  @override
  Future<String> getGroupKey(String token, String conversationId) async {
    return '';
  }
}

// ═══════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════

const String _currentUserId = 'current-user';
const String _token = 'test-token';

Message _createMessage({
  String id = 'msg-1',
  String conversationId = 'conv-1',
  String senderId = 'user-2',
  String senderName = 'Bob',
  String content = 'Hello!',
  MessageStatus status = MessageStatus.sent,
}) {
  return Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    senderName: senderName,
    content: content,
    createdAt: DateTime.now(),
    status: status,
  );
}

MessageRepositoryImpl _createRepo({
  required MockRemoteDataSource dataSource,
  required MockWebSocketService ws,
  required MockCryptoService crypto,
  required MockIdentityService identity,
  required MessagingService messaging,
  RatchetSessionStore? sessionStore,
}) {
  return MessageRepositoryImpl(
    remoteDataSource: dataSource,
    wsService: ws,
    crypto: crypto,
    identity: identity,
    messaging: messaging,
    tokenProvider: () => _token,
    userIdProvider: () => _currentUserId,
    sessionStore: sessionStore ?? _FakeRatchetSessionStore(),
  );
}

// ═══════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  late MockRemoteDataSource dataSource;
  late MockWebSocketService ws;
  late MockCryptoService crypto;
  late MockIdentityService identity;
  late MockMessagingService messaging;

  setUp(() {
    dataSource = MockRemoteDataSource();
    ws = MockWebSocketService();
    crypto = MockCryptoService();
    identity = MockIdentityService();
    messaging = MockMessagingService();
  });

  tearDown(() async {
    await ws.dispose();
  });

  group('MessageRepositoryImpl', () {
    group('sendMessage()', () {
      test('sends encrypted message and returns sent Message', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final result = await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Hello there',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        expect(dataSource.sendCallCount, 1);
        expect(result.status, MessageStatus.sent);
        expect(result.id, 'sent-msg-1');
        expect(result.content, 'Hello there');
        expect(result.senderId, _currentUserId);
      });

      test('returns failed message when send fails', () async {
        dataSource.shouldThrowOnSend = true;

        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final result = await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Will fail',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        expect(dataSource.sendCallCount, 1);
        expect(result.status, MessageStatus.failed);
        expect(result.content, 'Will fail');
      });

      test('adds sent message to message stream', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final messages = <Message>[];
        final sub = repo.observeMessages('conv-1').listen(messages.add);

        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Hi',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );
        await Future<void>.delayed(Duration.zero);

        expect(messages.length, 1);
        expect(messages.first.content, 'Hi');

        await sub.cancel();
      });
    });

    group('getMessages()', () {
      test('returns decrypted messages from data source', () async {
        dataSource.messagesToReturn.addAll([
          MessageDto(
            id: 'm1',
            conversationId: 'conv-1',
            senderId: 'user-2',
            senderName: '',
            ciphertext: base64Encode(utf8.encode('encrypted:Hi Bob')),
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        ]);

        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final messages = await repo.getMessages('conv-1');

        expect(dataSource.listCallCount, 1);
        expect(messages.length, 1);
        expect(messages.first.id, 'm1');
        expect(messages.first.senderName, 'Bob');
      });

      test('returns own messages and resolves sender', () async {
        // Message sent by the current user — uses own-message plaintext
        dataSource.messagesToReturn.addAll([
          MessageDto(
            id: 'm1',
            conversationId: 'conv-1',
            senderId: _currentUserId,
            senderName: '',
            ciphertext: base64Encode(utf8.encode('encrypted:Hello')),
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        ]);

        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // We need to have sent a message first so the plaintext is cached
        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Hello',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        // Clear the send call count and reset before getMessages
        dataSource.messagesToReturn[0] = MessageDto(
          id: 'sent-msg-1', // same ID as the sent message
          conversationId: 'conv-1',
          senderId: _currentUserId,
          senderName: '',
          ciphertext: 'irrelevant',
          createdAt: DateTime.now().toIso8601String(),
          status: 'sent',
        );

        final messages = await repo.getMessages('conv-1');

        expect(messages.length, 1);
        // Own messages should show "You" as sender name
        expect(messages.first.senderName, 'You');
      });

      test('throws when data source fails', () async {
        dataSource.shouldThrowOnList = true;

        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        expect(
          () => repo.getMessages('conv-1'),
          throwsException,
        );
      });
    });

    group('retryMessage()', () {
      test('resends failed message and returns new result', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final failed = _createMessage(
          id: '',
          content: 'Retry me',
          status: MessageStatus.failed,
        );

        final result = await repo.retryMessage('conv-1', failed);

        expect(dataSource.sendCallCount, 1);
        expect(result.status, MessageStatus.sent);
        expect(result.content, 'Retry me');
      });
    });

    group('observeMessages()', () {
      test('returns a stream that receives messages', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final messages = <Message>[];
        final sub = repo.observeMessages('conv-1').listen(messages.add);

        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Stream test',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );
        await Future<void>.delayed(Duration.zero);

        expect(messages.length, 1);
        expect(messages.first.content, 'Stream test');

        await sub.cancel();
      });
    });

    group('observeConnectionState()', () {
      test('emits connected state when WS connects', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final states = <domain.ConnectionState>[];
        final sub = repo.observeConnectionState().listen(states.add);

        ws.emitState(WsConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(states, contains(domain.ConnectionState.connected));

        await sub.cancel();
      });

      test('emits disconnected state when WS disconnects', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final states = <domain.ConnectionState>[];
        final sub = repo.observeConnectionState().listen(states.add);

        ws.emitState(WsConnectionState.disconnected);
        await Future<void>.delayed(Duration.zero);

        expect(states, contains(domain.ConnectionState.disconnected));

        await sub.cancel();
      });
    });

    group('failPendingMessages()', () {
      test('adds a failed message to the message stream', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        final messages = <Message>[];
        final sub = repo.observeMessages('conv-1').listen(messages.add);

        await repo.failPendingMessages('conv-1');
        await Future<void>.delayed(Duration.zero);

        expect(messages.length, 1);
        expect(messages.first.status, MessageStatus.failed);
        expect(messages.first.senderName, 'You');

        await sub.cancel();
      });

      test('does nothing for empty conversation ID', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // Should not throw
        await repo.failPendingMessages('');
      });
    });

    group('dispose()', () {
      test('cleans up all resources', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // Should not throw
        await repo.dispose();
      });

      test('is safe to call multiple times', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        await repo.dispose();
        await repo.dispose(); // second dispose should not throw
      });
    });

    group('Double Ratchet encryption/decryption', () {
      test('sendMessage encrypts via DR producing valid JSON envelope',
          () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Hello DR',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        expect(dataSource.sendCallCount, 1);
        // DR path was used (not shared-secret fallback)
        expect(crypto.encryptSharedCallCount, 0);
        // Drivate shared secret was derived for DR session creation
        expect(crypto.deriveCallCount, 1);
      });

      test('fallback to plaintext when no encryption possible', () async {
        // Uses _EmptyParticipantsMessaging → _findOtherParticipant returns null
        // → _sessionForSending returns null (no DR)
        // → _ensureSecret returns null (no shared secret either)
        // → plaintext is sent as-is (last resort)
        final messagingEmpty = _EmptyParticipantsMessaging();

        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messagingEmpty,
        );

        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Plaintext fallback',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        expect(dataSource.sendCallCount, 1);
        // Neither DR nor shared-secret was used (no participant available)
        expect(crypto.encryptSharedCallCount, 0);
        expect(crypto.deriveCallCount, 0);
      });

      test('getMessages resolves own-message plaintext from cache', () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // Send a message — populates _sentMessagePlaintexts
        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Cached hello',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        // Now set up DTO for own message with same ID as what was sent
        dataSource.messagesToReturn.add(
          MessageDto(
            id: 'sent-msg-1',
            conversationId: 'conv-1',
            senderId: _currentUserId,
            senderName: '',
            ciphertext: 'should-not-appear',
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        );

        final messages = await repo.getMessages('conv-1');

        expect(messages.length, 1);
        // Own-message plaintext resolution returns cached plaintext
        expect(messages.first.content, 'Cached hello');
        expect(messages.first.senderName, 'You');
        // Shared-secret decrypt was NOT called (we used cached plaintext)
        expect(crypto.decryptSharedCallCount, 0);
      });

      test('sendMessage stores plaintext for later getMessages retrieval',
          () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // Send two messages (same ID from mock, cache overwrites)
        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'First msg',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );
        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Second msg',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        // Set up own-message DTO matching the sent message ID
        dataSource.messagesToReturn.add(
          MessageDto(
            id: 'sent-msg-1',
            conversationId: 'conv-1',
            senderId: _currentUserId,
            senderName: '',
            ciphertext: 'irrelevant',
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        );

        final messages = await repo.getMessages('conv-1');

        expect(messages.length, 1);
        // Content comes from the in-memory cache (last sent, since same ID)
        expect(messages.first.content, isNot('irrelevant'));
      });

      test('getMessages decrypts other-user messages via shared-secret',
          () async {
        // Use normal MockMessagingService (has participants) so that
        // _ensureSecret succeeds. The ciphertext doesn't start with '{'
        // so the DR path is skipped automatically.
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        dataSource.messagesToReturn.add(
          MessageDto(
            id: 'm1',
            conversationId: 'conv-1',
            senderId: 'user-2',
            senderName: '',
            ciphertext: base64Encode(utf8.encode('encrypted:Secret!')),
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        );

        final messages = await repo.getMessages('conv-1');

        expect(messages.length, 1);
        // Decrypted via shared-secret fallback (ciphertext doesn't start with '{')
        expect(messages.first.content, 'Secret!');
        // decryptWithSharedKey was called
        expect(crypto.decryptSharedCallCount, 1);
        // Sender name resolved from participants
        expect(messages.first.senderName, 'Bob');
      });

      test('own-message plaintext persists across separate getMessages calls',
          () async {
        final repo = _createRepo(
          dataSource: dataSource,
          ws: ws,
          crypto: crypto,
          identity: identity,
          messaging: messaging,
        );

        // Send a message to populate cache
        await repo.sendMessage(
          conversationId: 'conv-1',
          plaintext: 'Persistent',
          currentUserId: _currentUserId,
          currentUserName: 'You',
        );

        // First getMessages with own-message DTO
        dataSource.messagesToReturn.add(
          MessageDto(
            id: 'sent-msg-1',
            conversationId: 'conv-1',
            senderId: _currentUserId,
            senderName: '',
            ciphertext: 'dummy',
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        );

        final msgs1 = await repo.getMessages('conv-1');
        expect(msgs1.first.content, 'Persistent');

        // Second getMessages — clear and add fresh DTO
        dataSource.messagesToReturn.clear();
        dataSource.messagesToReturn.add(
          MessageDto(
            id: 'sent-msg-1',
            conversationId: 'conv-1',
            senderId: _currentUserId,
            senderName: '',
            ciphertext: 'dummy',
            createdAt: DateTime.now().toIso8601String(),
            status: 'sent',
          ),
        );

        final msgs2 = await repo.getMessages('conv-1');
        expect(msgs2.first.content, 'Persistent');
      });
    });

    group('Double Ratchet algorithm (direct test)', () {
      test('initSender produces session with sendingChainKey', () async {
        final sharedSecret = List<int>.generate(32, (i) => i);
        final remotePub = List<int>.generate(32, (i) => i + 1);

        final session = await DoubleRatchet.initSender(sharedSecret, remotePub);

        expect(session.sendingChainKey, isNotNull);
        expect(session.rootKey.length, 32);
        expect(session.dhRemote, remotePub);
        expect(session.sendCount, 0);
      });

      test('initReceiver produces session without chain keys', () async {
        final x25519 = X25519();
        final keyPair = await (await x25519.newKeyPair()).extract();
        final sharedSecret = List<int>.generate(32, (i) => i);

        final session =
            await DoubleRatchet.initReceiver(sharedSecret, keyPair);

        expect(session.sendingChainKey, isNull);
        expect(session.receivingChainKey, isNull);
        expect(session.rootKey, sharedSecret);
      });

      test('full round-trip: initSender encrypt → initReceiver decrypt',
          () async {
        final sharedSecret = List<int>.generate(32, (i) => i);
        final x25519 = X25519();

        // Bob's identity key pair (receiver)
        final bobKeyPair = await (await x25519.newKeyPair()).extract();
        final bobPub = bobKeyPair.publicKey.bytes;

        // Alice creates sender session using Bob's actual public key
        final alice =
            await DoubleRatchet.initSender(sharedSecret, bobPub);

        // Alice encrypts a message
        final envelope = await DoubleRatchet.encrypt(alice, 'Hello from Alice');
        expect(envelope.header.messageNumber, 0);
        expect(envelope.header.previousChainLength, 0);
        expect(envelope.ciphertextBase64, isNotEmpty);

        // Bob creates receiver session with his identity key and shared secret
        final bob = await DoubleRatchet.initReceiver(sharedSecret, bobKeyPair);

        // Bob decrypts Alice's message
        // The first decrypt triggers a DH ratchet step:
        //   DH(bobPriv, aliceEphemeralPub) == DH(aliceEphemeralPriv, bobPub)
        // by the ECDH property, so the derived keys will match.
        final plaintext = await DoubleRatchet.decrypt(bob, envelope);
        expect(plaintext, 'Hello from Alice');

        // After decrypt, Bob should have chain keys set up
        expect(bob.receivingChainKey, isNotNull);
        expect(bob.sendingChainKey, isNotNull);
        expect(bob.receiveCount, 1);
      });

      test('round-trip with two messages (chain advance)', () async {
        final sharedSecret = List<int>.generate(32, (i) => i);
        final x25519 = X25519();

        // Bob's identity key pair (receiver)
        final bobKeyPair = await (await x25519.newKeyPair()).extract();
        final bobPub = bobKeyPair.publicKey.bytes;

        // Create sender session using Bob's actual public key
        final alice = await DoubleRatchet.initSender(sharedSecret, bobPub);

        // Alice sends two messages
        final env1 = await DoubleRatchet.encrypt(alice, 'Msg 1');
        expect(alice.sendCount, 1);

        final env2 = await DoubleRatchet.encrypt(alice, 'Msg 2');
        expect(alice.sendCount, 2);

        // Bob receives
        final bob = await DoubleRatchet.initReceiver(sharedSecret, bobKeyPair);

        // Bob decrypts both (in order)
        expect(await DoubleRatchet.decrypt(bob, env1), 'Msg 1');
        expect(bob.receiveCount, 1);

        expect(await DoubleRatchet.decrypt(bob, env2), 'Msg 2');
        expect(bob.receiveCount, 2);
      });

      test('serialization round-trip preserves session state', () async {
        final sharedSecret = List<int>.generate(32, (i) => i);
        final remotePub = List<int>.generate(32, (i) => i + 1);

        final session = await DoubleRatchet.initSender(sharedSecret, remotePub);

        // Encrypt one message to advance state
        await DoubleRatchet.encrypt(session, 'test');

        // Serialize and deserialize
        final json = session.toJson();
        final restored = DoubleRatchetSession.fromJson(json);

        expect(restored.sendCount, session.sendCount);
        expect(restored.rootKey, session.rootKey);
        expect(restored.sendingChainKey, session.sendingChainKey);
        expect(restored.dhSelf.type, KeyPairType.x25519);
      });

      test('RatchetEnvelope encodes and decodes correctly', () async {
        final header = RatchetHeader(
          dhPublicKey: List<int>.generate(32, (i) => i),
          previousChainLength: 5,
          messageNumber: 3,
        );
        final envelope =
            RatchetEnvelope(header, base64Encode([1, 2, 3, 4, 5]));

        final encoded = envelope.encode();
        final decoded = RatchetEnvelope.decode(encoded);

        expect(decoded.header.previousChainLength, 5);
        expect(decoded.header.messageNumber, 3);
        expect(decoded.header.dhPublicKey, header.dhPublicKey);
        expect(decoded.ciphertextBase64, envelope.ciphertextBase64);
      });
    });
  });
}
