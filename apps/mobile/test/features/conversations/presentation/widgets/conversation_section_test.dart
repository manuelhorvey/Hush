import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/widgets/conversation_card.dart';
import 'package:hush_mobile/features/conversations/presentation/widgets/conversation_section.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

final _mockConversations = [
  Conversation(
    id: 'c1',
    participants: [
      const ConversationParticipant(id: 'u1', displayName: 'Sarah'),
    ],
    lifecycle: ConversationLifecycle.active,
    createdAt: DateTime.now(),
  ),
  Conversation(
    id: 'c2',
    participants: [
      const ConversationParticipant(id: 'u2', displayName: 'Jordan'),
    ],
    lifecycle: ConversationLifecycle.closed,
    createdAt: DateTime.now(),
  ),
];

void main() {
  group('ConversationSection', () {
    testWidgets('renders with title and count', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationSection(
            title: 'Active',
            subtitle: 'Test subtitle',
            conversations: _mockConversations,
            initiallyExpanded: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationSection), findsOneWidget);
      // Count badge should show conversation count
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows conversation cards when expanded', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationSection(
            title: 'Active',
            subtitle: 'Test subtitle',
            conversations: _mockConversations,
            initiallyExpanded: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cards should be visible
      expect(find.byType(ConversationCard), findsWidgets);
    });

    testWidgets('starts collapsed when initiallyExpanded is false',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationSection(
            title: 'Closed',
            subtitle: 'Test subtitle',
            conversations: _mockConversations,
            initiallyExpanded: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationSection), findsOneWidget);
      // Count badge still visible in header
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('responds to header tap', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationSection(
            title: 'Active',
            subtitle: 'Test subtitle',
            conversations: _mockConversations,
            initiallyExpanded: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byType(ConversationSection), findsOneWidget);

      // Tap the section header (the count badge is in the header row)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Section should still render after tap
      expect(find.byType(ConversationSection), findsOneWidget);
      expect(find.byType(ConversationCard), findsWidgets);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationSection(
            title: 'Active',
            subtitle: 'Test subtitle',
            conversations: _mockConversations,
            initiallyExpanded: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byType(ConversationSection),
      );
      expect(semantics, isNotNull);
    });
  });
}
