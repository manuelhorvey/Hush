import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/screens/conversation_screen.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/conversation_input.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/date_separator.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/message_bubble.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message.dart';
import 'package:hush_mobile/features/messaging/presentation/providers/message_list_provider.dart';

class _TestNotifier extends MessageListNotifier {
  static DateTime _nowMinus(int minutes) =>
      DateTime.now().subtract(Duration(minutes: minutes));

  @override
  MessageListState build() {
    return MessageListState(
      status: MessageScreenStatus.loaded,
      messages: [
        Message(
          id: 'test_1',
          conversationId: 'conv_test',
          senderId: 'user_2',
          senderName: 'Sarah',
          content: 'Hey, how are you?',
          createdAt: _nowMinus(60),
        ),
        Message(
          id: 'test_2',
          conversationId: 'conv_test',
          senderId: 'user_1',
          senderName: 'You',
          content: "I'm great, thanks!",
          createdAt: _nowMinus(30),
        ),
      ],
      isActive: true,
      lifecycleStatus: 'active',
    );
  }

  @override
  Future<void> load(String conversationId) async {
    // No-op: already loaded with test data in build()
  }

  @override
  Future<bool> sendMessage(String plaintext) async => true;

  @override
  Future<void> retryMessage(Message failedMessage) async {}

  @override
  void markLifecycle({
    required bool isActive,
    required String lifecycleStatus,
    DateTime? completedAt,
  }) {}

  @override
  Future<void> loadMore() async {}
}

class _EmptyTestNotifier extends MessageListNotifier {
  @override
  MessageListState build() => MessageListState(
        status: MessageScreenStatus.loaded,
        messages: [],
        isActive: true,
        lifecycleStatus: 'active',
      );

  @override
  Future<void> load(String conversationId) async {}

  @override
  Future<bool> sendMessage(String plaintext) async => true;

  @override
  Future<void> retryMessage(Message failedMessage) async {}

  @override
  void markLifecycle({
    required bool isActive,
    required String lifecycleStatus,
    DateTime? completedAt,
  }) {}

  @override
  Future<void> loadMore() async {}
}

class _LoadingTestNotifier extends MessageListNotifier {
  @override
  MessageListState build() => const MessageListState(
        status: MessageScreenStatus.loading,
      );

  @override
  Future<void> load(String conversationId) async {}

  @override
  Future<bool> sendMessage(String plaintext) async => true;

  @override
  Future<void> retryMessage(Message failedMessage) async {}

  @override
  void markLifecycle({
    required bool isActive,
    required String lifecycleStatus,
    DateTime? completedAt,
  }) {}

  @override
  Future<void> loadMore() async {}
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      messageListProvider.overrideWith(() => _TestNotifier()),
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messageListProvider.overrideWith(() => _EmptyTestNotifier()),
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messageListProvider.overrideWith(() => _LoadingTestNotifier()),
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

      // Skeleton loading uses containers, not CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
