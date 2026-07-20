import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/feedback/inline_error.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('InlineError', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(_wrap(const InlineError(message: 'Invalid input')));
      expect(find.text('Invalid input'), findsOneWidget);
    });

    testWidgets('has liveRegion Semantics', (tester) async {
      await tester.pumpWidget(_wrap(const InlineError(message: 'Error occurred')));
      expect(
        tester.getSemantics(find.byType(InlineError)),
        matchesSemantics(
          label: 'Error: Error occurred',
          isLiveRegion: true,
        ),
      );
    });
  });

  group('SuccessMessage', () {
    testWidgets('renders success message', (tester) async {
      await tester.pumpWidget(_wrap(const SuccessMessage(message: 'All good')));
      expect(find.text('All good'), findsOneWidget);
    });
  });
}
