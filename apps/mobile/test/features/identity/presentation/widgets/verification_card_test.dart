import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/verification_state.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/verification_card.dart';

void main() {
  group('VerificationCard', () {
    const phrase = 'BLUE RIVER 92';

    Widget buildApp({
      required VerificationState state,
      VoidCallback? onStartVerification,
      VoidCallback? onConfirm,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: VerificationCard(
            state: state,
            phrase: phrase,
            onStartVerification: onStartVerification,
            onConfirm: onConfirm,
          ),
        ),
      );
    }

    testWidgets('renders security phrase', (tester) async {
      await tester.pumpWidget(buildApp(state: VerificationState.unknown));
      expect(find.text('BLUE RIVER 92'), findsOneWidget);
    });

    testWidgets('shows Start Verification button when callback provided',
        (tester) async {
      await tester.pumpWidget(buildApp(
        state: VerificationState.unknown,
        onStartVerification: () {},
      ));
      await tester.pumpAndSettle();
      expect(find.text('Start Verification'), findsOneWidget);
    });

    testWidgets('hides Start Verification when no callback',
        (tester) async {
      await tester.pumpWidget(buildApp(state: VerificationState.unknown));
      expect(find.text('Start Verification'), findsNothing);
    });

    testWidgets('shows Confirm Match when callback provided for pending',
        (tester) async {
      await tester.pumpWidget(buildApp(
        state: VerificationState.pending,
        onConfirm: () {},
      ));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Match'), findsOneWidget);
    });

    testWidgets('hides Confirm Match when no callback for pending',
        (tester) async {
      await tester.pumpWidget(buildApp(state: VerificationState.pending));
      expect(find.text('Confirm Match'), findsNothing);
    });

    testWidgets('shows verified confirmation for verified state',
        (tester) async {
      await tester.pumpWidget(buildApp(state: VerificationState.verified));
      expect(find.text('Identity verified'), findsOneWidget);
    });

    testWidgets('triggers onStartVerification', (tester) async {
      bool started = false;
      await tester.pumpWidget(buildApp(
        state: VerificationState.unknown,
        onStartVerification: () => started = true,
      ));

      await tester.tap(find.text('Start Verification'));
      expect(started, isTrue);
    });

    testWidgets('triggers onConfirm', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(buildApp(
        state: VerificationState.pending,
        onConfirm: () => confirmed = true,
      ));

      await tester.tap(find.text('Confirm Match'));
      expect(confirmed, isTrue);
    });
  });
}
