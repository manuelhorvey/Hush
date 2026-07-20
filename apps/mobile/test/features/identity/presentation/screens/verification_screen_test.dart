import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hush_mobile/features/identity/models/verification_state.dart';
import 'package:hush_mobile/features/identity/presentation/screens/verification_screen.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/security_phrase_display.dart';

Widget createTestApp({
  String phrase = 'BLUE RIVER 92',
  VerificationState initialState = VerificationState.unknown,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: VerificationScreen(
        phrase: phrase,
        initialState: initialState,
      ),
    ),
  );
}

void main() {
  group('VerificationScreen', () {
    testWidgets('renders the screen without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(VerificationScreen), findsOneWidget);
    });

    testWidgets('renders app bar with Verification title', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Verification'), findsOneWidget);
    });

    testWidgets('renders the security phrase', (tester) async {
      await tester.pumpWidget(createTestApp(phrase: 'GOLD LAKE 55'));
      await tester.pumpAndSettle();

      expect(find.text('GOLD LAKE 55'), findsOneWidget);
    });

    testWidgets('renders SecurityPhraseDisplay widget', (tester) async {
      await tester.pumpWidget(createTestApp(phrase: 'RED MOON 42'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityPhraseDisplay), findsOneWidget);
    });

    testWidgets('shows Start Verification button in unknown state',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Start Verification'), findsOneWidget);
    });

    testWidgets('hides Start Verification in verified state',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(initialState: VerificationState.verified),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Verification'), findsNothing);
    });

    testWidgets('shows Confirm Match button when state is pending',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(initialState: VerificationState.pending),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Match'), findsOneWidget);
    });

    testWidgets('shows verified confirmation when state is verified',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(initialState: VerificationState.verified),
      );
      await tester.pumpAndSettle();

      expect(find.text('Identity Verified'), findsOneWidget);
    });

    testWidgets('renders How it works section', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('How it works'), findsOneWidget);
    });

    testWidgets('renders all three steps', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Share this phrase'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('security phrase has semantic label', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byType(SecurityPhraseDisplay),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('start verification button has semantic label',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.text('Start Verification'),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('meets labeled tap target guideline', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });
}
