import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/verification_state.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/identity_badge.dart';

void main() {
  group('IdentityBadge', () {
    Widget buildApp({
      required String displayName,
      VerificationState state = VerificationState.unknown,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: IdentityBadge(
            displayName: displayName,
            verificationState: state,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('renders display name', (tester) async {
      await tester.pumpWidget(buildApp(displayName: 'Alex'));
      expect(find.text('Alex'), findsOneWidget);
    });

    testWidgets('renders verified label', (tester) async {
      await tester.pumpWidget(buildApp(
        displayName: 'Alex',
        state: VerificationState.verified,
      ));
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('renders unknown label by default', (tester) async {
      await tester.pumpWidget(buildApp(displayName: 'Alex'));
      expect(find.text('Not verified yet'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildApp(
        displayName: 'Alex',
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('Alex'));
      expect(tapped, isTrue);
    });
  });
}
