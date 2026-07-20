import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hush_mobile/features/identity/presentation/screens/device_management_screen.dart';

Widget createTestApp() {
  return ProviderScope(
    child: const MaterialApp(
      home: DeviceManagementScreen(),
    ),
  );
}

void main() {
  group('DeviceManagementScreen', () {
    testWidgets('renders the screen without errors', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(DeviceManagementScreen), findsOneWidget);
    });

    testWidgets('renders app bar with Devices title', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Devices'), findsOneWidget);
    });

    testWidgets('shows empty state when no devices', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('No devices'), findsOneWidget);
      expect(
        find.text('Your identity is only on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('renders refresh button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh'), findsOneWidget);
    });
  });
}
