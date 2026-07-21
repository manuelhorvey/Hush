import '../../../../core/config/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/device_dto.dart';
import '../models/identity_dto.dart';

abstract class IdentityRemoteDataSource {
  Future<IdentityDto> createIdentity({
    required String displayName,
    required String publicKey,
  });

  Future<IdentityDto> getIdentity(String userId);

  Future<List<DeviceDto>> getDevices();

  Future<void> removeDevice(String deviceId);

  Future<void> renameDevice(String deviceId, String newName);

  Future<String> createChallenge(String targetUserId);

  Future<bool> verifyChallenge(
      String challengeId, String signature);

  Future<void> storeExchangeKey(String x25519PublicKey);

  Future<String> getExchangeKey(String userId);
}

class IdentityRemoteDataSourceImpl implements IdentityRemoteDataSource {
  final ApiClient _client;

  IdentityRemoteDataSourceImpl({required this._client});

  @override
  Future<IdentityDto> createIdentity({
    required String displayName,
    required String publicKey,
  }) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: {
        'username': displayName,
        'public_key': publicKey,
      },
    );
    return IdentityDto.fromJson(response);
  }

  @override
  Future<IdentityDto> getIdentity(String userId) async {
    final response = await _client.get(ApiEndpoints.identityById(userId));
    return IdentityDto.fromJson(response);
  }

  @override
  Future<List<DeviceDto>> getDevices() async {
    final response = await _client.get(ApiEndpoints.devices);
    final list = response['devices'] as List<dynamic>;
    return list
        .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    await _client.delete(ApiEndpoints.deviceById(deviceId));
  }

  @override
  Future<void> renameDevice(String deviceId, String newName) async {
    await _client.patch(
      ApiEndpoints.deviceById(deviceId),
      data: {'device_name': newName},
    );
  }

  @override
  Future<String> createChallenge(String targetUserId) async {
    final response =
        await _client.post(ApiEndpoints.challenge(targetUserId));
    return response['challenge_id'] as String;
  }

  @override
  Future<bool> verifyChallenge(
      String challengeId, String signature) async {
    await _client.post(
      ApiEndpoints.verifyChallenge(challengeId),
      data: {'signature': signature},
    );
    return true;
  }

  @override
  Future<void> storeExchangeKey(String x25519PublicKey) async {
    await _client.post(
      ApiEndpoints.exchangeKey,
      data: {'public_key': x25519PublicKey},
    );
  }

  @override
  Future<String> getExchangeKey(String userId) async {
    final response =
        await _client.get(ApiEndpoints.exchangeKeyForUser(userId));
    return response['public_key'] as String;
  }
}
