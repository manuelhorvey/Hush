class DeviceDto {
  final String id;
  final String deviceName;
  final String deviceType;
  final bool isCurrent;
  final String? trustStatus;
  final DateTime createdAt;

  const DeviceDto({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.isCurrent,
    this.trustStatus,
    required this.createdAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id'] as String,
      deviceName: json['device_name'] as String,
      deviceType: json['device_type'] as String,
      isCurrent: json['is_current'] as bool? ?? false,
      trustStatus: json['trust_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_name': deviceName,
        'device_type': deviceType,
        'is_current': isCurrent,
        'trust_status': trustStatus,
        'created_at': createdAt.toIso8601String(),
      };
}
