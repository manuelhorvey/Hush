import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/data/conversation_detail_repository_impl.dart';
import 'package:hush_mobile/features/conversations/conversation/models/message.dart';

void main() {
  group('ConversationDetailRepositoryImpl', () {
    late ConversationDetailRepositoryImpl repo;

    setUp(() {
      repo = ConversationDetailRepositoryImpl();
    });

    test('getMessages returns messages for valid conversation', () async {
      final messages = await repo.getMessages('conv_1');

      expect(messages, isNotEmpty);
      expect(messages.first, isA<Message>());
    });

    test('getMessages returns empty list for unknown conversation', () async {
      final messages = await repo.getMessages('unknown_id');

      expect(messages, isEmpty);
    });

    test('getMessages returns messages with correct structure', () async {
      final messages = await repo.getMessages('conv_1');
      final first = messages.first;

      expect(first.id, isNotEmpty);
      expect(first.senderId, isNotEmpty);
      expect(first.senderName, isNotEmpty);
      expect(first.content, isNotEmpty);
      expect(first.createdAt, isA<DateTime>());
    });

    test('sendMessage adds message to conversation', () async {
      await repo.sendMessage('conv_1', 'New test message');
      final messages = await repo.getMessages('conv_1');

      final last = messages.last;
      expect(last.content, 'New test message');
      expect(last.senderName, 'You');
    });

    test('completeConversation changes status to completed', () async {
      final result = await repo.completeConversation('conv_1');

      expect(result, true);
      expect(repo.getStatus('conv_1'), 'completed');
    });

    test('destroyConversation removes messages and changes status', () async {
      final result = await repo.destroyConversation('conv_1');

      expect(result, true);
      expect(repo.getStatus('conv_1'), 'destroyed');
      final messages = await repo.getMessages('conv_1');
      expect(messages, isEmpty);
    });

    test('getStatus returns active for active conversations', () {
      expect(repo.getStatus('conv_1'), 'active');
    });

    test('getStatus returns completed for completed conversations', () {
      expect(repo.getStatus('conv_2'), 'completed');
    });

    test('getStatus returns active for unknown conversations', () {
      expect(repo.getStatus('unknown'), 'active');
    });
  });
}
