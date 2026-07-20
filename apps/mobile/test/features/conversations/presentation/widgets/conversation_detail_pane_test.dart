import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/widgets/conversation_detail_pane.dart';

Widget createTestApp(Conversation conversation) {
  return MaterialApp(
    home: Scaffold(
      body: ConversationDetailPane(
        conversation: conversation,
        onDeselect: () {},
      ),
    ),
  );
}

void main() {
  group('ConversationDetailPane', () {
    testWidgets('renders participant name', (tester) async {
      final conversation = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
        isVerified: true,
      );

      await tester.pumpWidget(createTestApp(conversation));
      await tester.pump();

      expect(find.text('Sarah'), findsOneWidget);
    });

    testWidgets('renders security status', (tester) async {
      final verified = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
        isVerified: true,
      );

      await tester.pumpWidget(createTestApp(verified));
      await tester.pump();

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('shows Private for unverified', (tester) async {
      final unverified = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
        isVerified: false,
      );

      await tester.pumpWidget(createTestApp(unverified));
      await tester.pump();

      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('shows lifecycle description', (tester) async {
      final active = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(active));
      await tester.pump();

      expect(find.text('Moment active'), findsOneWidget);
    });

    testWidgets('shows Open Conversation button for active', (tester) async {
      final active = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(active));
      await tester.pump();

      expect(find.text('Open Conversation'), findsOneWidget);
    });

    testWidgets('shows View Conversation button for closed', (tester) async {
      final closed = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.closed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(closed));
      await tester.pump();

      expect(find.text('View Conversation'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      final conversation = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(conversation));
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('calls onDeselect when close is tapped', (tester) async {
      bool called = false;
      final conversation = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConversationDetailPane(
            conversation: conversation,
            onDeselect: () => called = true,
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(called, true);
    });

    testWidgets('has accessibility semantics', (tester) async {
      final conversation = Conversation(
        id: 'conv_1',
        participants: [
          const ConversationParticipant(
            id: 'user_2',
            displayName: 'Sarah',
          ),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(conversation));
      await tester.pump();

      final semantics =
          tester.getSemantics(find.byType(ConversationDetailPane));
      expect(semantics, isNotNull);
    });
  });
}
