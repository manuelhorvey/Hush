import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/data/conversation_detail_repository_impl.dart';
import 'package:hush_mobile/features/conversations/conversation/domain/conversation_detail_repository.dart';
import 'package:hush_mobile/features/conversations/conversation/models/message.dart';
import 'package:hush_mobile/services/api_client.dart';
import 'package:hush_mobile/services/crypto_service.dart';
import 'package:hush_mobile/services/identity_service.dart';
import 'package:hush_mobile/services/local_cache_service.dart';
import 'package:hush_mobile/services/messaging_service.dart';
import 'package:hush_mobile/services/websocket_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://test');
}

class _StubCryptoService extends CryptoService {
  _StubCryptoService();
}

class _StubIdentityService extends IdentityService {
  _StubIdentityService() : super(api: _FakeApiClient());

  @override
  Future<String> getExchangeKey(String token, String userId) async => '';
}

class _MockMessagingService extends MessagingService {
  _MockMessagingService() : super(api: _FakeApiClient());

  @override
  Future<List<MessageInfo>> listMessages(
      String token, String conversationId) async {
    return [
      MessageInfo(
        id: 'msg-1',
        senderId: 'user-2',
        ciphertext: 'Hello!',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      ),
      MessageInfo(
        id: 'msg-2',
        senderId: 'user-1',
        ciphertext: 'Hi there!',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  @override
  Future<MessageInfo> sendMessage(
      String token, String conversationId, String ciphertext) async {
    return MessageInfo(
      id: 'msg-3',
      senderId: 'user-1',
      ciphertext: ciphertext,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<ConversationInfo>> listConversations(String token) async {
    return [
      ConversationInfo(
        id: 'conv-1',
        participants: [],
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  @override
  Future<ConversationInfo> completeConversation(
      String token, String conversationId) async {
    return ConversationInfo(
      id: conversationId,
      participants: [],
      status: 'completed',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

void main() {
  group('ConversationDetailRepositoryImpl', () {
    late ConversationDetailRepositoryImpl repo;
    late WebSocketService ws;

    setUp(() {
      ws = WebSocketService();
      repo = ConversationDetailRepositoryImpl(
        messaging: _MockMessagingService(),
        ws: ws,
        crypto: _StubCryptoService(),
        identity: _StubIdentityService(),
        cache: InMemoryCacheService(),
        tokenProvider: () => 'test-token',
        userIdProvider: () => 'user-1',
      );
    });

    tearDown(() async {
      await repo.dispose();
      await ws.dispose();
    });

    test('getMessages returns messages from API', () async {
      final messages = await repo.getMessages('conv-1');
      expect(messages, hasLength(2));
      expect(messages.first, isA<Message>());
    });

    test('getMessages maps senderId to display name', () async {
      final messages = await repo.getMessages('conv-1');
      expect(messages.first.senderName, 'Unknown');
      expect(messages.last.senderName, 'You');
    });

    test('sendMessage calls API and returns true on success', () async {
      final result = await repo.sendMessage('conv-1', 'New message');
      expect(result, isTrue);
    });

    test('completeConversation calls API and returns true', () async {
      final result = await repo.completeConversation('conv-1');
      expect(result, isTrue);
      final status = await repo.getStatus('conv-1');
      expect(status, DetailRepositoryStatus.completed);
    });

    test('getStatus returns destroyed for unknown conversation', () async {
      final status = await repo.getStatus('unknown-id');
      expect(status, DetailRepositoryStatus.destroyed);
    });

    test('messageStream returns a broadcast stream', () async {
      final stream = repo.messageStream('conv-1');
      expect(stream, isA<Stream<Message>>());
    });
  });
}
