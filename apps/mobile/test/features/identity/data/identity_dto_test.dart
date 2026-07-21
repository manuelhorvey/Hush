import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/data/models/device_dto.dart';
import 'package:hush_mobile/features/identity/data/models/identity_dto.dart';

void main() {
  group('IdentityDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'user-1',
        'display_name': 'Alice',
        'public_key': 'base64pubkey',
        'exchange_key': 'base64exkey',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = IdentityDto.fromJson(json);

      expect(dto.id, 'user-1');
      expect(dto.displayName, 'Alice');
      expect(dto.publicKey, 'base64pubkey');
      expect(dto.exchangeKey, 'base64exkey');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user-1',
        'display_name': 'Alice',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = IdentityDto.fromJson(json);

      expect(dto.publicKey, isNull);
      expect(dto.exchangeKey, isNull);
    });

    test('toJson produces correct output', () {
      final dto = IdentityDto(
        id: 'user-1',
        displayName: 'Alice',
        publicKey: 'pubkey',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = dto.toJson();

      expect(json['id'], 'user-1');
      expect(json['display_name'], 'Alice');
      expect(json['public_key'], 'pubkey');
    });
  });

  group('DeviceDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'dev-1',
        'device_name': 'My Phone',
        'device_type': 'mobile',
        'is_current': true,
        'trust_status': 'verified',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = DeviceDto.fromJson(json);

      expect(dto.id, 'dev-1');
      expect(dto.deviceName, 'My Phone');
      expect(dto.deviceType, 'mobile');
      expect(dto.isCurrent, isTrue);
      expect(dto.trustStatus, 'verified');
    });

    test('fromJson defaults isCurrent to false', () {
      final json = {
        'id': 'dev-1',
        'device_name': 'My Phone',
        'device_type': 'mobile',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = DeviceDto.fromJson(json);

      expect(dto.isCurrent, isFalse);
      expect(dto.trustStatus, isNull);
    });

    test('toJson produces correct output', () {
      final dto = DeviceDto(
        id: 'dev-1',
        deviceName: 'My Phone',
        deviceType: 'mobile',
        isCurrent: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final json = dto.toJson();

      expect(json['id'], 'dev-1');
      expect(json['device_name'], 'My Phone');
      expect(json['is_current'], isTrue);
    });
  });
}
