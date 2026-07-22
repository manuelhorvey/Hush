import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/domain/entities/device_identity.dart';

void main() {
  group('DeviceIdentity — domain entity', () {
    test('trusted device — trustLabel is correct', () {
      final device = DeviceIdentity(
        deviceId: 'd1',
        deviceName: 'My Phone',
        platform: 'mobile',
        createdAt: DateTime.now(),
        trustedStatus: DeviceTrustStatus.trusted,
      );

      expect(device.trustLabel, equals('Device trusted'));
    });

    test('pending device — trustLabel is correct', () {
      final device = DeviceIdentity(
        deviceId: 'd2',
        deviceName: 'New Device',
        platform: 'web',
        createdAt: DateTime.now(),
        trustedStatus: DeviceTrustStatus.pending,
      );

      expect(device.trustLabel, equals('Pending verification'));
    });

    test('revoked device — trustLabel is correct', () {
      final device = DeviceIdentity(
        deviceId: 'd3',
        deviceName: 'Old Device',
        platform: 'mobile',
        createdAt: DateTime.now(),
        trustedStatus: DeviceTrustStatus.revoked,
      );

      expect(device.trustLabel, equals('Access revoked'));
    });

    test('unknown device — trustLabel is correct', () {
      final device = DeviceIdentity(
        deviceId: 'd4',
        deviceName: 'Unknown',
        platform: 'mobile',
        createdAt: DateTime.now(),
        trustedStatus: DeviceTrustStatus.unknown,
      );

      expect(device.trustLabel, equals('Unknown device'));
    });

    test('displayCreatedAt — returns "Today" for now', () {
      final device = DeviceIdentity(
        deviceId: 'd5',
        deviceName: 'Test',
        platform: 'mobile',
        createdAt: DateTime.now(),
      );

      expect(device.displayCreatedAt, equals('Today'));
    });

    test('copyWith — preserves unchanged fields', () {
      final device = DeviceIdentity(
        deviceId: 'd1',
        deviceName: 'My Phone',
        platform: 'mobile',
        createdAt: DateTime.now(),
        trustedStatus: DeviceTrustStatus.pending,
      );

      final updated = device.copyWith(trustedStatus: DeviceTrustStatus.trusted);

      expect(updated.trustedStatus, equals(DeviceTrustStatus.trusted));
      expect(updated.deviceId, equals('d1'));
      expect(updated.deviceName, equals('My Phone'));
    });
  });
}
