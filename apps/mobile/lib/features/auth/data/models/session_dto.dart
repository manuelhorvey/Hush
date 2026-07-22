/// DTO for session response from the server.
class SessionResponseDto {
  final String token;
  final String refreshToken;
  final String userId;
  final String username;
  final String deviceId;
  final String? expiresAt;

  const SessionResponseDto({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.username,
    required this.deviceId,
    this.expiresAt,
  });

  factory SessionResponseDto.fromJson(Map<String, dynamic> json) {
    return SessionResponseDto(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      expiresAt: json['expires_at'] as String?,
    );
  }
}

/// DTO for device registration request.
class DeviceRegisterRequest {
  final String deviceName;
  final String publicKey;

  const DeviceRegisterRequest({
    required this.deviceName,
    required this.publicKey,
  });

  Map<String, dynamic> toJson() => {
        'device_name': deviceName,
        'public_key': publicKey,
      };
}

/// DTO for device registration response.
class DeviceRegisterResponseDto {
  final String deviceId;
  final String deviceName;
  final String publicKey;
  final String createdAt;
  final String status;

  const DeviceRegisterResponseDto({
    required this.deviceId,
    required this.deviceName,
    required this.publicKey,
    required this.createdAt,
    required this.status,
  });

  factory DeviceRegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return DeviceRegisterResponseDto(
      deviceId: json['id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      publicKey: json['public_key'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// DTO for exchange key request.
class ExchangeKeyRequest {
  final String x25519PublicKey;

  const ExchangeKeyRequest({required this.x25519PublicKey});

  Map<String, dynamic> toJson() => {
        'x25519_public_key': x25519PublicKey,
      };
}
