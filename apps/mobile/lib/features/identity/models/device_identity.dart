enum TrustStatus { trusted, pending, unknown }

class DeviceIdentity {
  final String id;
  final String deviceName;
  final String? deviceType;
  final DateTime createdAt;
  final bool isCurrentDevice;
  final TrustStatus trustStatus;

  const DeviceIdentity({
    required this.id,
    required this.deviceName,
    this.deviceType,
    required this.createdAt,
    this.isCurrentDevice = false,
    this.trustStatus = TrustStatus.unknown,
  });

  String get createdAtFormatted {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} months ago';
    return '${diff.inDays ~/ 365} years ago';
  }
}
