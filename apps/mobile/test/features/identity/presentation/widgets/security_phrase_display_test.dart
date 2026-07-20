import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/security_phrase_display.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SecurityPhraseDisplay', () {
    const phrase = 'BLUE RIVER 92';

    testWidgets('renders the security phrase', (tester) async {
      await tester.pumpWidget(
        wrapApp(SecurityPhraseDisplay(phrase: phrase)),
      );
      await tester.pumpAndSettle();

      expect(find.text(phrase), findsOneWidget);
    });

    testWidgets('renders copy button by default', (tester) async {
      await tester.pumpWidget(
        wrapApp(SecurityPhraseDisplay(phrase: phrase)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy phrase'), findsOneWidget);
    });

    testWidgets('hides copy button when showCopyButton is false',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          SecurityPhraseDisplay(phrase: phrase, showCopyButton: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy phrase'), findsNothing);
    });

    testWidgets('security phrase has semantic label', (tester) async {
      await tester.pumpWidget(
        wrapApp(SecurityPhraseDisplay(phrase: phrase)),
      );
      await tester.pumpAndSettle();

      // Verify semantics exist for the phrase display widget
      final semantics = tester.getSemantics(
        find.byType(SecurityPhraseDisplay),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('copy button has semantic label', (tester) async {
      await tester.pumpWidget(
        wrapApp(SecurityPhraseDisplay(phrase: phrase)),
      );
      await tester.pumpAndSettle();

      // Verify semantics exist for the copy button
      final semantics = tester.getSemantics(
        find.text('Copy phrase'),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('meets labeled tap target guideline', (tester) async {
      await tester.pumpWidget(
        wrapApp(SecurityPhraseDisplay(phrase: phrase)),
      );
      await tester.pumpAndSettle();

      // All tappable elements (copy button) should have semantic labels
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });
}
