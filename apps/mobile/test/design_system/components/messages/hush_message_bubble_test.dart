import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/messages/hush_message_bubble.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('HushMessageBubble', () {
    testWidgets('renders sent message', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Hello',
        isMe: true,
        timestamp: '10:30',
      )));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders received message with sender name', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Hi there',
        isMe: false,
        senderName: 'Alice',
        timestamp: '10:31',
      )));
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows sending indicator', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Sending...',
        isMe: true,
        timestamp: '10:32',
        status: MessageStatus.sending,
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows failed state', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Oops',
        isMe: true,
        timestamp: '10:33',
        status: MessageStatus.failed,
      )));
      expect(find.text('Failed to send'), findsOneWidget);
    });

    testWidgets('shows delivered state', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Delivered',
        isMe: true,
        timestamp: '10:34',
        status: MessageStatus.delivered,
      )));
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('has correct Semantics for sent message', (tester) async {
      await tester.pumpWidget(_wrap(HushMessageBubble(
        text: 'Secret',
        isMe: true,
        timestamp: '10:35',
      )));
      final semantics = tester.getSemantics(find.text('Secret').last);
      expect(semantics, isNotNull);
      // The merged semantics label includes the message text
      expect(semantics.label, contains('You said: Secret'));
    });
  });
}
