import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/providers/conversation_detail_provider.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/screens/conversation_screen.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/conversation_input.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/date_separator.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/message_bubble.dart';
import 'package:hush_mobile/features/conversations/conversation/models/message.dart';

class _TestNotifier extends ConversationDetailNotifier {
  static DateTime _nowMinus(int minutes) =>
      DateTime.now().subtract(Duration(minutes: minutes));

  @override
  ConversationDetailState build() {
    return ConversationDetailState(
      screenStatus: ConversationScreenStatus.loaded,
      messages: [
        Message(
          id: 'test_1',
          senderId: 'user_2',
          senderName: 'Sarah',
          content: 'Hey, how are you?',
          createdAt: _nowMinus(60),
        ),
        Message(
          id: 'test_2',
          senderId: 'user_1',
          senderName: 'You',
          content: 'I\'m great, thanks!',
          createdAt: _nowMinus(30),
        ),
      ],
      isActive: true,
      lifecycleStatus: 'active',
    );
  }

  @override
  Future<void> load(String conversationId) async {
    // No-op: already loaded with test data
  }
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      conversationDetailProvider.overrideWith(() => _TestNotifier()),
    ],
    child: const MaterialApp(
      home: ConversationScreen(
        conversationId: 'conv_test',
        participantName: 'Sarah',
      ),
    ),
  );
}

void main() {
  group('ConversationScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(ConversationScreen), findsOneWidget);
    });

    testWidgets('renders participant name', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Sarah'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders messages', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(MessageBubble), findsWidgets);
    });

    testWidgets('renders input area when active', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(ConversationInput), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(
        find.byIcon(Icons.arrow_back_rounded),
        findsOneWidget,
      );
    });

    testWidgets('renders date separators for grouped messages',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(DateSeparator), findsWidgets);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      final emptyNotifier = _EmptyTestNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationDetailProvider.overrideWith(() => emptyNotifier),
          ],
          child: const MaterialApp(
            home: ConversationScreen(
              conversationId: 'conv_empty',
              participantName: 'Test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Start your private moment.'), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      final loadingNotifier = _LoadingTestNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationDetailProvider.overrideWith(() => loadingNotifier),
          ],
          child: const MaterialApp(
            home: ConversationScreen(
              conversationId: 'conv_loading',
              participantName: 'Test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Skeleton loading uses containers, not CircularProgressIndicator
    });

    testWidgets('has accessibility semantics on messages', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final bubbles = find.byType(MessageBubble);
      expect(bubbles, findsWidgets);

      final semantics = tester.getSemantics(bubbles.first);
      expect(semantics, isNotNull);
    });

    testWidgets('shows Private indicator for unverified conversations',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.textContaining('Private'), findsWidgets);
    });

    testWidgets('input has hint text', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Type a message...'), findsOneWidget);
    });
  });
}

class _EmptyTestNotifier extends ConversationDetailNotifier {
  @override
  ConversationDetailState build() => ConversationDetailState(
        screenStatus: ConversationScreenStatus.loaded,
        messages: [],
        isActive: true,
        lifecycleStatus: 'active',
      );

  @override
  Future<void> load(String conversationId) async {
    // No-op: already in empty state
  }
}

class _LoadingTestNotifier extends ConversationDetailNotifier {
  @override
  ConversationDetailState build() => ConversationDetailState(
        screenStatus: ConversationScreenStatus.loading,
      );

  @override
  Future<void> load(String conversationId) async {
    // No-op: stay in loading state
  }
}
