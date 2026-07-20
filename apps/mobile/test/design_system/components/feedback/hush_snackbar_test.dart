import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/feedback/hush_snackbar.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('HushSnackbar', () {
    testWidgets('shows snackbar with message', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (context) => ElevatedButton(
          onPressed: () => HushSnackbar.show(
            context: context,
            message: 'Saved successfully',
            type: SnackbarType.success,
          ),
          child: const Text('Show'),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Saved successfully'), findsOneWidget);
    });
  });
}
