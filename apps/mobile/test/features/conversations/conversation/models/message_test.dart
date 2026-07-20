import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/models/message.dart';

void main() {
  group('Message', () {
    final now = DateTime(2026, 7, 20, 14, 30);

    test('creates with all fields', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: now,
      );

      expect(message.id, 'msg_1');
      expect(message.senderId, 'user_1');
      expect(message.senderName, 'Alex');
      expect(message.content, 'Hello');
      expect(message.status, MessageStatus.sent);
    });

    test('default status is sent', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: now,
      );

      expect(message.status, MessageStatus.sent);
    });

    test('timeString formats correctly', () {
      final morning = DateTime(2026, 7, 20, 9, 5);
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: morning,
      );

      expect(message.timeString, '09:05');
    });

    test('relativeTime shows Just now for recent messages', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(message.relativeTime, 'Just now');
    });

    test('relativeTime shows minutes for messages within an hour', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      expect(message.relativeTime, '15m ago');
    });

    test('dateGroupKey returns Today for today', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: DateTime.now(),
      );

      expect(message.dateGroupKey, 'Today');
    });

    test('dateGroupKey returns Yesterday for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Alex',
        content: 'Hello',
        createdAt: yesterday,
      );

      expect(message.dateGroupKey, 'Yesterday');
    });

    test('accessibilityLabel includes sender, content, and time', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_2',
        senderName: 'Sarah',
        content: 'Are you free?',
        createdAt: now,
      );

      expect(message.accessibilityLabel, contains('Sarah'));
      expect(message.accessibilityLabel, contains('Are you free?'));
      expect(message.accessibilityLabel, contains('14:30'));
    });

    test('can create message with failed status', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'You',
        content: 'Hello',
        createdAt: now,
        status: MessageStatus.failed,
      );

      expect(message.status, MessageStatus.failed);
    });

    test('can create message with sending status', () {
      final message = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'You',
        content: 'Hello',
        createdAt: now,
        status: MessageStatus.sending,
      );

      expect(message.status, MessageStatus.sending);
    });
  });
}
