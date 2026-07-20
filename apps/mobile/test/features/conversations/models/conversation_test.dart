import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';

void main() {
  group('Conversation', () {
    final now = DateTime.now();

    final activeConv = Conversation(
      id: 'c1',
      participants: [
        const ConversationParticipant(id: 'u1', displayName: 'Sarah'),
      ],
      lifecycle: ConversationLifecycle.active,
      createdAt: now.subtract(const Duration(hours: 2)),
      isVerified: true,
    );

    final closedConv = Conversation(
      id: 'c2',
      participants: [
        const ConversationParticipant(id: 'u2', displayName: 'Jordan'),
      ],
      lifecycle: ConversationLifecycle.closed,
      createdAt: now.subtract(const Duration(days: 2)),
      completedAt: now.subtract(const Duration(hours: 6)),
      isVerified: false,
    );

    test('displayName returns single participant name', () {
      expect(activeConv.displayName, 'Sarah');
    });

    test('displayName returns group name for multiple participants', () {
      final group = Conversation(
        id: 'c3',
        participants: [
          const ConversationParticipant(id: 'u1', displayName: 'Sarah'),
          const ConversationParticipant(id: 'u2', displayName: 'Alex'),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: now,
      );
      expect(group.displayName, 'Sarah +1');
    });

    test('isOpen returns true for active lifecycle', () {
      expect(ConversationLifecycle.active.isOpen, isTrue);
    });

    test('isOpen returns true for waiting lifecycle', () {
      expect(ConversationLifecycle.waiting.isOpen, isTrue);
    });

    test('isOpen returns false for closed lifecycle', () {
      expect(ConversationLifecycle.closed.isOpen, isFalse);
    });

    test('lifecycle labels are non-empty for all states', () {
      for (final state in ConversationLifecycle.values) {
        expect(state.label.isNotEmpty, isTrue);
      }
    });

    test('lifecycle descriptions are present for all states', () {
      for (final state in ConversationLifecycle.values) {
        expect(state.description.isNotEmpty, isTrue);
      }
    });

    test('accessibilityLabel contains participant name for active', () {
      expect(
        activeConv.accessibilityLabel,
        contains('Sarah'),
      );
    });

    test('accessibilityLabel contains security state', () {
      expect(activeConv.accessibilityLabel, contains('Verified'));
      expect(closedConv.accessibilityLabel, contains('Private'));
    });

    test('accessibilityLabel contains lifecycle description', () {
      expect(
        activeConv.accessibilityLabel,
        contains('Moment active'),
      );
    });

    test('relativeTime returns Today for today', () {
      final todayConv = Conversation(
        id: 'c4',
        participants: [
          const ConversationParticipant(id: 'u1', displayName: 'Test'),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(todayConv.relativeTime, 'Today');
    });

    test('relativeTime returns Yesterday for yesterday', () {
      final yesterday = Conversation(
        id: 'c5',
        participants: [
          const ConversationParticipant(id: 'u1', displayName: 'Test'),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(yesterday.relativeTime, 'Yesterday');
    });

    test('completedRelativeTime returns correct for closed conversations',
        () {
      expect(closedConv.completedRelativeTime, 'Today');
    });

    test('completedRelativeTime returns empty for non-closed', () {
      expect(activeConv.completedRelativeTime, '');
    });
  });
}
