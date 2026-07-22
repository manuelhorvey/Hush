/// A device bound to a user's identity.
///
/// Devices represent trusted endpoints. Each device has its own identity
/// and trust status. The architecture supports multiple trusted devices
/// (preparation for future multi-device support), but synchronization
/// across devices is not implemented here.
class DeviceIdentity {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime createdAt;
  final DeviceTrustStatus trustedStatus;

  const DeviceIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    this.trustedStatus = DeviceTrustStatus.pending,
  });

  DeviceIdentity copyWith({
    String? deviceId,
    String? deviceName,
    String? platform,
    DateTime? createdAt,
    DeviceTrustStatus? trustedStatus,
  }) {
    return DeviceIdentity(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      trustedStatus: trustedStatus ?? this.trustedStatus,
    );
  }

  String get displayCreatedAt {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  /// User-friendly trust description.
  String get trustLabel {
    return switch (trustedStatus) {
      DeviceTrustStatus.trusted => 'Device trusted',
      DeviceTrustStatus.pending => 'Pending verification',
      DeviceTrustStatus.revoked => 'Access revoked',
      DeviceTrustStatus.unknown => 'Unknown device',
    };
  }
}

/// Trust status for a device.
///
/// Language preference: use "trusted" rather than "authenticated".
/// Users understand trust intuitively.
enum DeviceTrustStatus {
  /// Device is trusted and can access the user's identity.
  trusted,

  /// Device registration is pending verification.
  pending,

  /// Device access has been revoked.
  revoked,

  /// Trust status is not yet determined.
  unknown;
}
