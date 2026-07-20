import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/privacy_education_card.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('PrivacyEducationCard', () {
    testWidgets('renders title for verified variant', (tester) async {
      await tester.pumpWidget(wrapApp(const PrivacyEducationCard.verified()));
      expect(find.text('What does verified mean?'), findsOneWidget);
    });

    testWidgets('renders title for private variant', (tester) async {
      await tester.pumpWidget(wrapApp(const PrivacyEducationCard.private()));
      expect(find.text('What does private mean?'), findsOneWidget);
    });

    testWidgets('renders title for deviceTrust variant', (tester) async {
      await tester.pumpWidget(
        wrapApp(const PrivacyEducationCard.deviceTrust()),
      );
      expect(find.text('What is a trusted device?'), findsOneWidget);
    });

    testWidgets('expands to show explanation on tap', (tester) async {
      await tester.pumpWidget(
        wrapApp(const PrivacyEducationCard.verified()),
      );

      // Tap the expansion tile header
      await tester.tap(find.text('What does verified mean?'));
      await tester.pumpAndSettle();

      // Explanation text should now be visible
      expect(
        find.textContaining('Verification helps you confirm'),
        findsOneWidget,
      );
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        wrapApp(const PrivacyEducationCard.private()),
      );

      expect(
        find.bySemanticsLabel('Privacy education: What does private mean?'),
        findsOneWidget,
      );
    });

    testWidgets('shows dismiss button when onDismiss provided', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          PrivacyEducationCard.verified(onDismiss: () {}),
        ),
      );

      expect(find.byTooltip('Dismiss'), findsOneWidget);
    });

    testWidgets('hides dismiss button when onDismiss is null', (tester) async {
      await tester.pumpWidget(
        wrapApp(const PrivacyEducationCard.verified()),
      );

      expect(find.byTooltip('Dismiss'), findsNothing);
    });
  });
}
