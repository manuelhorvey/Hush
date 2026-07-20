import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/buttons/hush_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('HushButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(HushButton(label: 'Create', onPressed: () {})));
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(HushButton(
        label: 'Tap Me',
        onPressed: () => tapped = true,
      )));
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner when loading', (tester) async {
      await tester.pumpWidget(_wrap(HushButton(
        label: 'Save',
        loading: true,
        onPressed: () {},
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(HushButton(label: 'Disabled')));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(_wrap(HushButton(label: 'Submit', onPressed: () {})));
      final semantics = tester.getSemantics(find.byType(FilledButton));
      expect(semantics.label, 'Submit');
      expect(semantics.getSemanticsData().hasFlag(SemanticsFlag.isEnabled),
          isTrue);
    });
  });

  group('HushOutlineButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(HushOutlineButton(label: 'Cancel', onPressed: () {})));
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('HushTextButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(HushTextButton(label: 'Learn more', onPressed: () {})));
      expect(find.text('Learn more'), findsOneWidget);
    });
  });

  group('HushDangerButton', () {
    testWidgets('renders with destructive label', (tester) async {
      await tester.pumpWidget(_wrap(HushDangerButton(label: 'Delete', onPressed: () {})));
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
