import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/cards/section_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SectionCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(SectionCard(
        title: const Text('Settings'),
        subtitle: const Text('Subtitle text'),
      )));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SectionCard(
        title: const Text('Tap here'),
        onTap: () => tapped = true,
      )));
      await tester.tap(find.text('Tap here'));
      expect(tapped, isTrue);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(const SectionHeader(title: 'Account')));
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('renders action label', (tester) async {
      await tester.pumpWidget(_wrap(SectionHeader(
        title: 'Devices',
        actionLabel: 'Manage',
        onAction: () {},
      )));
      expect(find.text('Manage'), findsOneWidget);
    });
  });
}
