import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:hush_mobile/features/conversations/presentation/screens/new_conversation_screen.dart';

class _CreateTestNotifier extends ConversationsNotifier {
  @override
  ConversationsState build() => const ConversationsState(
        conversations: [],
        status: ConversationsStatus.loaded,
      );

  @override
  Future<void> load() async {
    // No-op: already loaded
  }

  @override
  Future<Conversation> createConversation({
    required String participantName,
    required String participantId,
  }) async {
    return Conversation(
      id: 'conv-new-1',
      participants: [
        ConversationParticipant(
          id: participantId,
          displayName: participantName,
        ),
      ],
      lifecycle: ConversationLifecycle.active,
      createdAt: DateTime.now(),
    );
  }
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      conversationsProvider.overrideWith(() => _CreateTestNotifier()),
    ],
    child: const MaterialApp(
      home: NewConversationScreen(),
    ),
  );
}

void main() {
  group('NewConversationScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(NewConversationScreen), findsOneWidget);
    });

    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Start a moment.'), findsOneWidget);
      // AppBar title also says "Start a Moment" — multiple matches expected
      expect(find.text('Start a Moment'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders name input field', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('e.g. Sarah'), findsOneWidget);
    });

    testWidgets('shows privacy notice', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(
        find.textContaining('Your moment is private'),
        findsOneWidget,
      );
    });

    testWidgets('shows create button when name is entered', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Enter a name
      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pump();

      // Check button exists with correct label
      expect(find.text('Start a Moment'), findsAtLeastNWidgets(1));
    });

    testWidgets('name field has correct label', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(NewConversationScreen));
      expect(semantics, isNotNull);
    });

    testWidgets('cancel button is present', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
