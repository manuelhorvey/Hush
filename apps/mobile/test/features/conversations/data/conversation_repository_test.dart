import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/data/conversation_repository_impl.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/services/api_client.dart';
import 'package:hush_mobile/services/local_cache_service.dart';
import 'package:hush_mobile/services/messaging_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://test');
}

class _MockMessagingService extends MessagingService {
  _MockMessagingService() : super(api: _FakeApiClient());

  @override
  Future<List<ConversationInfo>> listConversations(String token) async {
    return [
      ConversationInfo(
        id: 'conv-1',
        participants: [
          ParticipantInfo(userId: 'user-2', username: 'Sarah'),
        ],
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
      ),
      ConversationInfo(
        id: 'conv-2',
        participants: [
          ParticipantInfo(userId: 'user-3', username: 'Alex'),
        ],
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
    ];
  }

  @override
  Future<List<UserInfo>> searchUsers(String token, String query) async {
    return [
      UserInfo(id: 'user-1', username: 'Alice'),
    ];
  }
}

void main() {
  group('ConversationRepositoryImpl', () {
    late ConversationRepositoryImpl repo;

    setUp(() {
      repo = ConversationRepositoryImpl(
        messaging: _MockMessagingService(),
        cache: InMemoryCacheService(),
        tokenProvider: () => 'test-token',
      );
    });

    test('listConversations maps API response to domain models', () async {
      final data = await repo.listConversations();
      expect(data.length, 2);
      expect(data[0].id, 'conv-1');
      expect(data[0].lifecycle, ConversationLifecycle.active);
      expect(data[0].participants.length, 1);
      expect(data[0].participants.first.displayName, 'Sarah');
    });

    test('completed conversation maps to closed lifecycle', () async {
      final data = await repo.listConversations();
      expect(data[1].lifecycle, ConversationLifecycle.closed);
    });

    test('searchUsers returns matching users', () async {
      final results = await repo.searchUsers('Alice');
      expect(results.length, 1);
      expect(results.first.username, 'Alice');
    });
  });
}
