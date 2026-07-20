import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/verification_state.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/trust_indicator.dart';

void main() {
  group('TrustIndicator', () {
    Widget buildApp(VerificationState state) {
      return MaterialApp(
        home: Scaffold(
          body: TrustIndicator(state: state),
        ),
      );
    }

    testWidgets('renders for unknown state', (tester) async {
      await tester.pumpWidget(buildApp(VerificationState.unknown));
      expect(find.byType(TrustIndicator), findsOneWidget);
    });

    testWidgets('renders for verified state', (tester) async {
      await tester.pumpWidget(buildApp(VerificationState.verified));
      expect(find.byType(TrustIndicator), findsOneWidget);
    });

    testWidgets('renders for pending state', (tester) async {
      await tester.pumpWidget(buildApp(VerificationState.pending));
      expect(find.byType(TrustIndicator), findsOneWidget);
    });

    testWidgets('renders for warning state', (tester) async {
      await tester.pumpWidget(buildApp(VerificationState.warning));
      expect(find.byType(TrustIndicator), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildApp(VerificationState.verified));
      expect(
        find.bySemanticsLabel('Trust status: Verified'),
        findsOneWidget,
      );
    });
  });
}
