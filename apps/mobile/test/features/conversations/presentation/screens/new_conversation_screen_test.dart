import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/providers/websocket_service_provider.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:hush_mobile/features/conversations/presentation/screens/new_conversation_screen.dart';
import 'package:hush_mobile/services/websocket_service.dart';

class _CreateTestNotifier extends ConversationsNotifier {
  @override
  ConversationsState build() => const ConversationsState(
        conversations: [],
        status: ConversationsStatus.loaded,
      );

  @override
  Future<void> load() async {}

  @override
  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  }) async {
    return Conversation(
      id: 'conv-new-1',
      participants: participantIds
          .map((id) => ConversationParticipant(
                id: id,
                displayName: id,
              ))
          .toList(),
      lifecycle: ConversationLifecycle.active,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<({String id, String username})>> searchUsers(
      String query) async {
    return [
      (id: 'user-sarah', username: 'Sarah'),
      (id: 'user-sam', username: 'Sam'),
    ];
  }
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      webSocketServiceProvider.overrideWithValue(WebSocketService()),
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
      expect(find.text('Start a Moment'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders search input field', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search by name...'), findsOneWidget);
    });

    testWidgets('shows search results after typing', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Sa');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets('shows create button after selecting user', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Sa');
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Sarah'));
      await tester.pump();

      expect(find.text('Start Moment'), findsOneWidget);
    });

    testWidgets('shows privacy notice after selecting user', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Sa');
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Sam'));
      await tester.pump();

      expect(
        find.textContaining('Your moment is private'),
        findsOneWidget,
      );
    });

    testWidgets('search field has correct label', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Search'), findsOneWidget);
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
