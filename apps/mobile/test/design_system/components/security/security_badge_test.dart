import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/security/security_badge.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('SecurityBadge', () {
    testWidgets('renders Private variant', (tester) async {
      await tester.pumpWidget(_wrap(const SecurityBadge.private()));
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('renders Verified variant', (tester) async {
      await tester.pumpWidget(_wrap(const SecurityBadge.verified()));
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('renders Warning variant', (tester) async {
      await tester.pumpWidget(_wrap(const SecurityBadge.warning()));
      expect(find.text('Warning'), findsOneWidget);
    });

    testWidgets('all variants have Semantics label', (tester) async {
      await tester.pumpWidget(_wrap(const SecurityBadge.private()));
      expect(
        tester.getSemantics(find.byType(SecurityBadge)),
        matchesSemantics(label: 'Private'),
      );
    });
  });
}
