import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/indicators/empty_section.dart';

void main() {
  group('HushEmptySection', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const HushEmptySection(
              title: 'No active conversations.',
            ),
          ),
        ),
      );

      expect(find.text('No active conversations.'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const HushEmptySection(
              title: 'No active conversations.',
              subtitle: 'Start a new conversation when you\'re ready.',
            ),
          ),
        ),
      );

      expect(find.text('No active conversations.'), findsOneWidget);
      expect(
        find.text('Start a new conversation when you\'re ready.'),
        findsOneWidget,
      );
    });

    testWidgets('renders without subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const HushEmptySection(
              title: 'No items.',
            ),
          ),
        ),
      );

      expect(find.text('No items.'), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const HushEmptySection(
              title: 'No active conversations.',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.text('No active conversations.'),
      );
      expect(semantics, isNotNull);
    });
  });
}
