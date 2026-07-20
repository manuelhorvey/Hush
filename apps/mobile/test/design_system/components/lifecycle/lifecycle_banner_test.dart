import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/design_system/components/lifecycle/lifecycle_banner.dart';
import 'package:hush_mobile/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: HushTheme.light, home: Scaffold(body: child));
}

void main() {
  group('LifecycleBanner', () {
    testWidgets('active lifecycle shows nothing', (tester) async {
      await tester.pumpWidget(_wrap(
        const LifecycleBanner(lifecycle: ConversationLifecycle.active),
      ));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('closed lifecycle shows message', (tester) async {
      await tester.pumpWidget(_wrap(
        const LifecycleBanner(lifecycle: ConversationLifecycle.closed),
      ));
      expect(find.textContaining('completed'), findsOneWidget);
    });

    testWidgets('destroyed lifecycle shows message', (tester) async {
      await tester.pumpWidget(_wrap(
        const LifecycleBanner(lifecycle: ConversationLifecycle.destroyed),
      ));
      expect(find.textContaining('gone'), findsOneWidget);
    });

    testWidgets('has liveRegion Semantics', (tester) async {
      await tester.pumpWidget(_wrap(
        const LifecycleBanner(lifecycle: ConversationLifecycle.destroyed),
      ));
      expect(
        tester.getSemantics(find.byType(LifecycleBanner)),
        matchesSemantics(
          label: 'This moment is gone.',
          isLiveRegion: true,
        ),
      );
    });
  });
}
