// ignore_for_file: prefer_initializing_formals

import 'api_client.dart';

class DeviceInfo {
  final String id;
  final String deviceName;
  final String publicKey;
  final String createdAt;

  DeviceInfo({
    required this.id,
    required this.deviceName,
    required this.publicKey,
    required this.createdAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String,
      deviceName: json['device_name'] as String,
      publicKey: json['public_key'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class IdentityService {
  final ApiClient _api;

  IdentityService({required ApiClient api}) : _api = api;

  Future<DeviceInfo> registerDevice(
      String token, String deviceName, String publicKey) async {
    final data = await _api.post(
      '/api/v1/identity/devices',
      {'device_name': deviceName, 'public_key': publicKey},
      token: token,
    );
    return DeviceInfo.fromJson(data);
  }

  Future<List<DeviceInfo>> listDevices(String token) async {
    final data = await _api.get('/api/v1/identity/devices', token: token);
    final devices = data['devices'] as List<dynamic>;
    return devices
        .map((d) => DeviceInfo.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createChallenge(
      String token, String targetUserId) async {
    return await _api.post(
      '/api/v1/identity/challenge',
      {'target_user_id': targetUserId},
      token: token,
    );
  }

  Future<bool> verifyChallenge(
      String token, String challengeId, String signature) async {
    final data = await _api.post(
      '/api/v1/identity/verify',
      {'challenge_id': challengeId, 'signature': signature},
      token: token,
    );
    return data['verified'] as bool;
  }
}
