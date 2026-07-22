import '../entities/device_identity.dart';

/// Abstract repository for device identity management.
///
/// Handles device registration, trust status, and multi-device
/// preparation (future: remote device removal).
abstract class DeviceRepository {
  /// Register the current device with the server.
  /// Returns the registered [DeviceIdentity].
  Future<DeviceIdentity> registerDevice({
    required String token,
    required String deviceName,
    required String publicKey,
  });

  /// Store the X25519 exchange key for the current device.
  Future<void> storeExchangeKey({
    required String token,
    required String x25519PublicKey,
  });

  /// Get the exchange key for a given user.
  Future<String> getExchangeKey({
    required String token,
    required String userId,
  });

  /// List all devices associated with the current user.
  Future<List<DeviceIdentity>> listDevices({required String token});

  /// Remove a device by its ID.
  Future<void> removeDevice({
    required String token,
    required String deviceId,
  });

  /// Rename a device.
  Future<void> renameDevice({
    required String token,
    required String deviceId,
    required String newName,
  });
}
