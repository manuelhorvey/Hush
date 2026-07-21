import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/providers/websocket_service_provider.dart';
import 'package:hush_mobile/features/conversations/domain/conversation_repository.dart';
import 'package:hush_mobile/features/conversations/models/conversation.dart';
import 'package:hush_mobile/features/conversations/presentation/providers/conversation_repository_provider.dart';
import 'package:hush_mobile/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:hush_mobile/features/conversations/presentation/screens/home_screen.dart';
import 'package:hush_mobile/features/conversations/presentation/widgets/conversation_search.dart';
import 'package:hush_mobile/services/websocket_service.dart';

class _FakeConversationRepository implements ConversationRepository {
  @override
  Future<List<Conversation>> listConversations() async => [
        Conversation(
          id: 'conv-1',
          participants: const [
            ConversationParticipant(id: 'user-2', displayName: 'Test User'),
          ],
          createdAt: DateTime.now(),
        ),
      ];

  @override
  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Conversation> completeConversation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> destroyConversation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<({String id, String username})>> searchUsers(String query) async {
    throw UnimplementedError();
  }
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      webSocketServiceProvider.overrideWithValue(WebSocketService()),
      conversationRepositoryProvider.overrideWithValue(
        _FakeConversationRepository(),
      ),
    ],
    child: const MaterialApp(
      home: HomeScreen(),
    ),
  );
}

class _EmptyNotifier extends ConversationsNotifier {
  @override
  ConversationsState build() => const ConversationsState(
    conversations: [],
    status: ConversationsStatus.empty,
  );

  @override
  Future<void> load() async {} // no-op: already in empty state
}

Widget createEmptyApp() {
  return ProviderScope(
    overrides: [
      webSocketServiceProvider.overrideWithValue(WebSocketService()),
      conversationRepositoryProvider.overrideWithValue(
        _FakeConversationRepository(),
      ),
      conversationsProvider.overrideWith(() => _EmptyNotifier()),
    ],
    child: const MaterialApp(
      home: HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('renders Hush header', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Hush'), findsOneWidget);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ConversationSearch), findsOneWidget);
    });

    testWidgets('renders floating action button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('identity avatar is present in header', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Avatar shows '?' when no identity is loaded
      expect(find.text('?'), findsOneWidget);

      // Verify semantics exist for the avatar
      final semantics = tester.getSemantics(find.text('?'));
      expect(semantics, isNotNull);
    });

    testWidgets('search field has hint text', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Search by name'), findsOneWidget);
    });

    group('empty state', () {
      testWidgets('shows empty title when no conversations exist', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        expect(find.text('No moments yet'), findsOneWidget);
      });

      testWidgets('shows empty description', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        expect(find.textContaining('Start a private moment'), findsOneWidget);
      });

      testWidgets('shows New Conversation button in empty state', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        expect(find.text('Start a Moment'), findsOneWidget);
      });

      testWidgets('empty state has Start a Moment button', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        expect(find.byType(FilledButton), findsOneWidget);
      });

      testWidgets('empty state shows empty icon', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        // Icon may appear in both the list pane and companion pane on desktop
        expect(
          find.byIcon(Icons.chat_bubble_outline_rounded),
          findsAtLeastNWidgets(1),
        );
      });

      testWidgets('does not show sections when empty', (tester) async {
        await tester.pumpWidget(createEmptyApp());
        await tester.pump();

        // Active section should not be present
        expect(find.text('Active Moments'), findsNothing);
        // Past Moments section should not be present
        expect(find.text('Past Moments'), findsNothing);
        // Search should not be present in empty-all state
        expect(find.byType(ConversationSearch), findsNothing);
      });
    });
  });
}
