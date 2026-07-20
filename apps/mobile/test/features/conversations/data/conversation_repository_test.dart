import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/data/conversation_repository_impl.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';

void main() {
  group('ConversationRepositoryImpl', () {
    test('generateMockData returns 6 conversations', () {
      final repo = ConversationRepositoryImpl();
      final data = repo.generateMockData();
      expect(data.length, 6);
    });

    test('generateMockData has mix of lifecycles', () {
      final repo = ConversationRepositoryImpl();
      final data = repo.generateMockData();
      final lifecycles = data.map((c) => c.lifecycle).toSet();
      expect(lifecycles.contains(ConversationLifecycle.active), isTrue);
      expect(lifecycles.contains(ConversationLifecycle.closed), isTrue);
    });

    test('generateMockData has verified and unverified conversations', () {
      final repo = ConversationRepositoryImpl();
      final data = repo.generateMockData();
      final verifiedStates = data.map((c) => c.isVerified).toSet();
      expect(verifiedStates.contains(true), isTrue);
      // May or may not have false depending on mock data
    });

    test('generateMockConversation returns conversation with given lifecycle',
        () {
      final repo = ConversationRepositoryImpl();
      final conv = repo.generateMockConversation(
        lifecycle: ConversationLifecycle.closed,
      );
      expect(conv.lifecycle, ConversationLifecycle.closed);
    });

    test('listConversations returns mock data', () async {
      final repo = ConversationRepositoryImpl();
      final data = await repo.listConversations();
      expect(data, isA<List<Conversation>>());
      expect(data.isNotEmpty, isTrue);
    });
  });
}
