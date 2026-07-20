import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/device_identity.dart';
import 'package:hush_mobile/features/identity/presentation/widgets/device_card.dart';

void main() {
  group('DeviceCard', () {
    final device = DeviceIdentity(
      id: 'd1',
      deviceName: 'iPhone 15',
      createdAt: DateTime.now(),
      isCurrentDevice: true,
      trustStatus: TrustStatus.trusted,
    );

    Widget buildApp(DeviceIdentity d) {
      return MaterialApp(
        home: Scaffold(
          body: DeviceCard(device: d),
        ),
      );
    }

    testWidgets('renders device name', (tester) async {
      await tester.pumpWidget(buildApp(device));
      expect(find.text('iPhone 15'), findsOneWidget);
    });

    testWidgets('shows Current badge for current device', (tester) async {
      await tester.pumpWidget(buildApp(device));
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('hides Current badge for non-current device', (tester) async {
      final nonCurrent = DeviceIdentity(
        id: 'd2',
        deviceName: 'MacBook',
        createdAt: DateTime.now(),
        isCurrentDevice: false,
        trustStatus: TrustStatus.trusted,
      );
      await tester.pumpWidget(buildApp(nonCurrent));
      expect(find.text('Current'), findsNothing);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildApp(device));
      expect(
        find.bySemanticsLabel('iPhone 15. Trusted device. Today'),
        findsOneWidget,
      );
    });
  });
}
