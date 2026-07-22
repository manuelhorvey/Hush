import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message_status.dart';
import 'package:hush_mobile/features/messaging/presentation/controllers/message_controller.dart';

Message _msg({
  required String id,
  String conversationId = 'conv-1',
  String senderId = 'user-1',
  String senderName = 'Alice',
  String content = 'Hello',
  MessageStatus status = MessageStatus.sent,
  DateTime? createdAt,
}) {
  return Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    senderName: senderName,
    content: content,
    createdAt: createdAt ?? DateTime.now(),
    status: status,
  );
}

void main() {
  group('MessageController', () {
    late MessageController controller;

    setUp(() {
      controller = MessageController();
    });

    group('reset()', () {
      test('replaces all messages', () {
        controller.reset([_msg(id: '1'), _msg(id: '2')]);
        expect(controller.length, 2);
        expect(controller.messages.map((m) => m.id), ['1', '2']);
      });

      test('replaces previous messages', () {
        controller.reset([_msg(id: '1'), _msg(id: '2')]);
        controller.reset([_msg(id: '3')]);
        expect(controller.length, 1);
        expect(controller.messages.first.id, '3');
      });

      test('accepts empty list', () {
        controller.reset([_msg(id: '1')]);
        controller.reset([]);
        expect(controller.length, 0);
      });

      test('deduplicates by ID during reset (last wins)', () {
        controller.reset([
          _msg(id: '1', content: 'first'),
          _msg(id: '1', content: 'second'),
        ]);
        expect(controller.length, 1);
        expect(controller.messages.first.content, 'second');
      });
    });

    group('append()', () {
      test('adds messages to the end', () {
        controller.append([_msg(id: '1'), _msg(id: '2')]);
        expect(controller.messages.map((m) => m.id), ['1', '2']);
      });

      test('appends after existing messages', () {
        controller.reset([_msg(id: '1')]);
        controller.append([_msg(id: '2')]);
        expect(controller.messages.map((m) => m.id), ['1', '2']);
      });

      test('deduplicates — does not add messages with existing IDs', () {
        controller.reset([_msg(id: '1', content: 'original')]);
        controller.append([_msg(id: '1', content: 'newer')]);
        expect(controller.length, 1);
        expect(controller.messages.first.content, 'original');
      });

      test('accepts empty list', () {
        controller.reset([_msg(id: '1')]);
        controller.append([]);
        expect(controller.length, 1);
      });
    });

    group('prepend()', () {
      test('adds messages to the beginning', () {
        controller.prepend([_msg(id: '1')]);
        expect(controller.messages.first.id, '1');
      });

      test('prepends before existing messages', () {
        controller.reset([_msg(id: '2')]);
        controller.prepend([_msg(id: '1')]);
        expect(controller.messages.map((m) => m.id), ['1', '2']);
      });

      test('prepends multiple messages in order', () {
        controller.reset([_msg(id: '3')]);
        controller.prepend([_msg(id: '1'), _msg(id: '2')]);
        expect(controller.messages.map((m) => m.id), ['1', '2', '3']);
      });

      test('deduplicates — prepended message wins when ID exists in prior messages', () {
        controller.reset([_msg(id: '2', content: 'second')]);
        controller.prepend([_msg(id: '1', content: 'first'), _msg(id: '2', content: 'replaced')]);
        // After clear: new messages added first ('1'/'first', '2'/'replaced')
        // Then existing restored but '2' already exists → skipped
        // Result: [1/'first', 2/'replaced']
        expect(controller.length, 2);
        expect(controller.messages[0].id, '1');
        expect(controller.messages[0].content, 'first');
        expect(controller.messages[1].id, '2');
        expect(controller.messages[1].content, 'replaced');
      });
    });

    group('update()', () {
      test('updates an existing message by ID', () {
        controller.reset([_msg(id: '1', content: 'hello')]);
        controller.update(_msg(id: '1', content: 'updated'));
        expect(controller.messages.first.content, 'updated');
      });

      test('does nothing when message ID does not exist', () {
        controller.reset([_msg(id: '1')]);
        controller.update(_msg(id: '2', content: 'ghost'));
        expect(controller.length, 1);
        expect(controller.messages.first.id, '1');
      });
    });

    group('remove()', () {
      test('removes a message by ID', () {
        controller.reset([_msg(id: '1'), _msg(id: '2')]);
        controller.remove('1');
        expect(controller.messages.map((m) => m.id), ['2']);
      });

      test('does nothing when ID does not exist', () {
        controller.reset([_msg(id: '1')]);
        controller.remove('nonexistent');
        expect(controller.length, 1);
      });
    });

    group('get()', () {
      test('returns message by ID', () {
        controller.reset([_msg(id: '1', content: 'find me')]);
        final found = controller.get('1');
        expect(found, isNotNull);
        expect(found!.content, 'find me');
      });

      test('returns null when ID not found', () {
        final found = controller.get('nonexistent');
        expect(found, isNull);
      });
    });

    group('clear()', () {
      test('removes all messages', () {
        controller.reset([_msg(id: '1'), _msg(id: '2')]);
        controller.clear();
        expect(controller.length, 0);
        expect(controller.messages, isEmpty);
      });

      test('is idempotent', () {
        controller.clear();
        expect(controller.length, 0);
      });
    });

    group('length', () {
      test('returns 0 for empty controller', () {
        expect(controller.length, 0);
      });

      test('returns correct count after reset', () {
        controller.reset([_msg(id: '1'), _msg(id: '2'), _msg(id: '3')]);
        expect(controller.length, 3);
      });
    });

    group('messages', () {
      test('returns messages in insertion order (oldest first)', () {
        controller.reset([_msg(id: '1'), _msg(id: '2'), _msg(id: '3')]);
        expect(controller.messages.map((m) => m.id), ['1', '2', '3']);
      });

      test('returns a copy — modifying returned list does not affect internal state', () {
        controller.reset([_msg(id: '1')]);
        controller.messages.add(_msg(id: '2'));
        expect(controller.length, 1);
      });
    });

    group('groupByDate()', () {
      test('returns empty list when no messages', () {
        final grouped = controller.groupByDate();
        expect(grouped, isEmpty);
      });

      test('groups messages by Today', () {
        final now = DateTime.now();
        controller.reset([
          _msg(id: '1', createdAt: now.subtract(const Duration(hours: 1))),
          _msg(id: '2', createdAt: now.subtract(const Duration(hours: 2))),
        ]);
        final grouped = controller.groupByDate();
        expect(grouped.length, 1);
        expect(grouped[0].$1, 'Today');
        expect(grouped[0].$2.length, 2);
      });

      test('groups messages by Yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        controller.reset([
          _msg(id: '1', createdAt: yesterday),
        ]);
        final grouped = controller.groupByDate();
        expect(grouped.length, 1);
        expect(grouped[0].$1, 'Yesterday');
      });

      test('groups messages in correct order: Today → Yesterday → Earlier → Older', () {
        final now = DateTime.now();
        controller.reset([
          _msg(id: '3', createdAt: now.subtract(const Duration(days: 10))),
          _msg(id: '1', createdAt: now.subtract(const Duration(hours: 1))),
          _msg(id: '2', createdAt: now.subtract(const Duration(days: 1))),
        ]);
        final grouped = controller.groupByDate();
        expect(grouped.length, 3);
        expect(grouped[0].$1, 'Today');
        expect(grouped[1].$1, 'Yesterday');
        // Last group is the oldest date
      });
    });
  });
}
