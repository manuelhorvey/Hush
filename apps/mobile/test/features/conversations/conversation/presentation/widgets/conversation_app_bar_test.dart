import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/conversation/presentation/widgets/conversation_app_bar.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(appBar: child as PreferredSizeWidget),
  );
}

void noop() {}

void main() {
  group('ConversationAppBar subtitle states', () {

    testWidgets('verified active shows Private • Trusted', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Private • Trusted'), findsOneWidget);
    });

    testWidgets('unverified active shows Private • Verify Identity',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Private • Verify Identity'), findsOneWidget);
    });

    testWidgets('completed with recent completedAt shows closing timer',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'completed',
            completedAt: DateTime.now().subtract(const Duration(hours: 2)),
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show a closing countdown (either hours or minutes)
      expect(find.textContaining('Closing'), findsOneWidget);
    });

    testWidgets('completed without completedAt shows Moment Complete',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'completed',
            completedAt: null,
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Moment Complete'), findsOneWidget);
    });

    testWidgets('completed with old completedAt shows Moment Complete',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'completed',
            completedAt:
                DateTime.now().subtract(const Duration(hours: 48)),
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Moment Complete'), findsOneWidget);
    });

    testWidgets('completed with ~23h50m old completedAt shows minutes',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'completed',
            completedAt:
                DateTime.now().subtract(const Duration(minutes: 23 * 60 + 50)),
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show a minutes countdown
      expect(find.textContaining('Closing in'), findsOneWidget);
    });

    testWidgets('completed with 1h old completedAt shows closing indicator',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'completed',
            completedAt:
                DateTime.now().subtract(const Duration(hours: 1)),
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Shows either 'Closing Tomorrow' or 'Closing in Xh' depending on current time
      expect(find.textContaining('Closing'), findsOneWidget);
    });

    testWidgets('destroyed shows Gone', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: false,
            isActive: false,
            lifecycleStatus: 'destroyed',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gone'), findsOneWidget);
    });
  });

  group('ConversationAppBar rendering', () {

    testWidgets('renders display name', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Olivia'), findsOneWidget);
    });

    testWidgets('renders avatar letter', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First letter of display name used as avatar
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top-level semantics
      final semantics = tester.getSemantics(
        find.byType(ConversationAppBar),
      );
      expect(semantics, isNotNull);

      // Back button semantics
      expect(find.bySemanticsLabel('Back'), findsOneWidget);

      // Options button semantics
      expect(find.bySemanticsLabel('Moment options'), findsOneWidget);
    });

    testWidgets('shows Complete Moment in menu when isActive',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: true,
            lifecycleStatus: 'active',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the overflow menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Complete Moment'), findsOneWidget);
    });

    testWidgets('hides Complete Moment in menu when not isActive',
        (tester) async {
      await tester.pumpWidget(
        wrapApp(
          ConversationAppBar(
            displayName: 'Olivia',
            isVerified: true,
            isActive: false,
            lifecycleStatus: 'completed',
            onViewProfile: noop,
            onVerifyIdentity: noop,
            onComplete: noop,
            onSecurityDetails: noop,
            onDestroy: noop,
            onReport: noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the overflow menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Complete Moment'), findsNothing);
    });

    testWidgets('View Profile menu item fires callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onViewProfile: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Verify Identity menu item fires callback',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onVerifyIdentity: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify Identity'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Complete Moment menu item fires callback',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onComplete: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Moment'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Security Details menu item fires callback',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onSecurityDetails: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security Details'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Report menu item fires callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onReport: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Let Go menu item fires callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(wrapApp(_buildAppBar(
        onDestroy: () => called = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Let Go'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}

Widget _buildAppBar({
  VoidCallback onViewProfile = noop,
  VoidCallback onVerifyIdentity = noop,
  VoidCallback onComplete = noop,
  VoidCallback onSecurityDetails = noop,
  VoidCallback onReport = noop,
  VoidCallback onDestroy = noop,
}) {
  return ConversationAppBar(
    displayName: 'Olivia',
    isVerified: true,
    isActive: true,
    lifecycleStatus: 'active',
    onViewProfile: onViewProfile,
    onVerifyIdentity: onVerifyIdentity,
    onComplete: onComplete,
    onSecurityDetails: onSecurityDetails,
    onDestroy: onDestroy,
    onReport: onReport,
  );
}
