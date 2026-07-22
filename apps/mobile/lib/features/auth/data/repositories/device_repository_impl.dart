import 'package:flutter/foundation.dart';

import '../../../../services/identity_service.dart';
import '../../domain/entities/device_identity.dart';
import '../../domain/repositories/device_repository.dart';

/// Implementation of [DeviceRepository].
///
/// Delegates to the legacy [IdentityService] for API calls while
/// providing clean domain-level abstractions for the presentation layer.
class DeviceRepositoryImpl implements DeviceRepository {
  final IdentityService _identityService;

  DeviceRepositoryImpl({
    required IdentityService identityService,
  }) : _identityService = identityService;

  @override
  Future<DeviceIdentity> registerDevice({
    required String token,
    required String deviceName,
    required String publicKey,
  }) async {
    final info = await _identityService.registerDevice(token, deviceName, publicKey);
    return DeviceIdentity(
      deviceId: info.id,
      deviceName: info.deviceName,
      platform: _detectPlatform(),
      createdAt: DateTime.tryParse(info.createdAt) ?? DateTime.now(),
      trustedStatus: DeviceTrustStatus.trusted,
    );
  }

  @override
  Future<void> storeExchangeKey({
    required String token,
    required String x25519PublicKey,
  }) async {
    await _identityService.storeExchangeKey(token, x25519PublicKey);
  }

  @override
  Future<String> getExchangeKey({
    required String token,
    required String userId,
  }) async {
    return _identityService.getExchangeKey(token, userId);
  }

  @override
  Future<List<DeviceIdentity>> listDevices({required String token}) async {
    final rawDevices = await _identityService.listDevices(token);
    return rawDevices.map((d) {
      return DeviceIdentity(
        deviceId: d.id,
        deviceName: d.deviceName,
        platform: _detectPlatform(),
        createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
        trustedStatus: DeviceTrustStatus.trusted,
      );
    }).toList();
  }

  @override
  Future<void> removeDevice({
    required String token,
    required String deviceId,
  }) async {
    await _identityService.removeDevice(token, deviceId);
  }

  @override
  Future<void> renameDevice({
    required String token,
    required String deviceId,
    required String newName,
  }) async {
    await _identityService.renameDevice(token, deviceId, newName);
  }

  String _detectPlatform() {
    // Platform detection using kIsWeb + defaultPlatform
    if (kIsWeb) return 'web';
    return 'mobile';
  }
}
