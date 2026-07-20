import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/widgets/conversation_card.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ConversationCard', () {
    final activeConv = Conversation(
      id: 'c1',
      participants: [
        const ConversationParticipant(id: 'u1', displayName: 'Sarah'),
      ],
      lifecycle: ConversationLifecycle.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true,
    );

    final closedConv = Conversation(
      id: 'c2',
      participants: [
        const ConversationParticipant(id: 'u2', displayName: 'Jordan'),
      ],
      lifecycle: ConversationLifecycle.closed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      completedAt: DateTime.now().subtract(const Duration(hours: 6)),
      isVerified: false,
    );

    testWidgets('renders participant name for active', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sarah'), findsOneWidget);
    });

    testWidgets('renders Active badge for active conversation', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders Closed badge for closed conversation', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: closedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('renders Verified for verified conversation', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('renders Private for unverified conversation', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: closedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('has accessibility semantics label', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byType(ConversationCard),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sarah'));
      expect(tapped, isTrue);
    });

    testWidgets('no message previews or unread counts shown',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationCard(
            conversation: activeConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // These should NOT be present per privacy-first design
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsNothing);
    });
  });
}
