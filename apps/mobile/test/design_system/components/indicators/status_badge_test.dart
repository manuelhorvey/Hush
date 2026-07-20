import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/indicators/status_badge.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('StatusBadge', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(label: 'Active')));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(label: 'Completed')));
      expect(
        tester.getSemantics(find.byType(StatusBadge)),
        matchesSemantics(label: 'Completed'),
      );
    });

    testWidgets('renders all variants without error', (tester) async {
      for (final variant in BadgeVariant.values) {
        await tester.pumpWidget(_wrap(StatusBadge(
          label: variant.name,
          variant: variant,
        )));
        expect(find.text(variant.name), findsOneWidget);
      }
    });
  });
}
