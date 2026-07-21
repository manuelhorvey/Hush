import '../../../../core/config/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_dto.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseDto> register(
      String username, String publicKey);
  Future<AuthResponseDto> login(String username);
  Future<RefreshResponseDto> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl({required this._client});

  @override
  Future<AuthResponseDto> register(
      String username, String publicKey) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: RegisterRequest(username: username, publicKey: publicKey).toJson(),
    );
    return AuthResponseDto.fromJson(response);
  }

  @override
  Future<AuthResponseDto> login(String username) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: LoginRequest(username: username).toJson(),
    );
    return AuthResponseDto.fromJson(response);
  }

  @override
  Future<RefreshResponseDto> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiEndpoints.refreshToken,
      data: RefreshRequest(refreshToken: refreshToken).toJson(),
    );
    return RefreshResponseDto.fromJson(response);
  }
}
