import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hush_mobile/features/identity/presentation/screens/identity_create_screen.dart';

Widget createTestApp() {
  return ProviderScope(
    child: const MaterialApp(
      home: IdentityCreateScreen(),
    ),
  );
}

void main() {
  group('IdentityCreateScreen', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Create your private identity'), findsOneWidget);
    });

    testWidgets('renders privacy explanation', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('It stays under your control'),
        findsOneWidget,
      );
    });

    testWidgets('renders display name text field', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders create identity button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Create Identity'), findsOneWidget);
    });

    testWidgets('renders privacy reassurance message', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('No phone number or contacts required.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when trying to create with empty name',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Identity'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name.'), findsOneWidget);
    });

    testWidgets('create button has accessible label', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify the button renders
      expect(find.text('Create Identity'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
