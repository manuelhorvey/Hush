import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/device_identity.dart';

void main() {
  group('DeviceIdentity', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 5));

    test('createdAtFormatted returns Today for today', () {
      final device = DeviceIdentity(
        id: 'd1',
        deviceName: 'iPhone',
        createdAt: today,
      );
      expect(device.createdAtFormatted, 'Today');
    });

    test('createdAtFormatted returns Yesterday for yesterday', () {
      final device = DeviceIdentity(
        id: 'd2',
        deviceName: 'MacBook',
        createdAt: yesterday,
      );
      expect(device.createdAtFormatted, 'Yesterday');
    });

    test('createdAtFormatted returns days ago for recent', () {
      final device = DeviceIdentity(
        id: 'd3',
        deviceName: 'iPad',
        createdAt: lastWeek,
      );
      expect(device.createdAtFormatted, '5 days ago');
    });

    test('isCurrentDevice defaults to false', () {
      final device = DeviceIdentity(
        id: 'd4',
        deviceName: 'Test',
        createdAt: today,
      );
      expect(device.isCurrentDevice, isFalse);
    });

    test('trustStatus defaults to unknown', () {
      final device = DeviceIdentity(
        id: 'd5',
        deviceName: 'Test',
        createdAt: today,
      );
      expect(device.trustStatus, TrustStatus.unknown);
    });
  });
}
