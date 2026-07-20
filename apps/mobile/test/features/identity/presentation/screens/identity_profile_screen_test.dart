import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hush_mobile/features/identity/presentation/screens/identity_profile_screen.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/security_status_card.dart';

Widget createTestApp() {
  return ProviderScope(
    child: const MaterialApp(
      home: IdentityProfileScreen(),
    ),
  );
}

void main() {
  group('IdentityProfileScreen', () {
    testWidgets('renders the screen without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(IdentityProfileScreen), findsOneWidget);
    });

    testWidgets('renders app bar with Identity title', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Identity'), findsOneWidget);
    });

    testWidgets('renders Security status cards', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(SecurityStatusCard), findsWidgets);
    });

    testWidgets('renders privacy settings button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Privacy settings'), findsOneWidget);
    });
  });
}
