import '../../../../core/network/network_errors.dart';
import '../../domain/identity_failure.dart';
import '../../domain/identity_repository.dart';
import '../../models/device_identity.dart';
import '../../models/user_identity.dart';
import '../../models/verification_state.dart';
import '../datasources/identity_remote_datasource.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  final IdentityRemoteDataSource _remoteDataSource;

  IdentityRepositoryImpl({
    required this._remoteDataSource,
  });

  @override
  Future<UserIdentity> createIdentity({
    required String token,
    required String displayName,
  }) async {
    try {
      final dto = await _remoteDataSource.createIdentity(
        displayName: displayName,
        publicKey: token,
      );
      return UserIdentity(
        id: dto.id,
        displayName: dto.displayName,
        createdAt: dto.createdAt,
      );
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<List<DeviceIdentity>> listDevices(String token) async {
    try {
      final dtos = await _remoteDataSource.getDevices();
      return dtos.map((d) {
        return DeviceIdentity(
          id: d.id,
          deviceName: d.deviceName,
          deviceType: d.deviceType,
          createdAt: d.createdAt,
          isCurrentDevice: d.isCurrent,
        );
      }).toList();
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> confirmDevice(String token, String deviceId) async {
    try {
      await _remoteDataSource.renameDevice(deviceId, '');
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> removeDevice(String token, String deviceId) async {
    try {
      await _remoteDataSource.removeDevice(deviceId);
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> renameDevice(
      String token, String deviceId, String newName) async {
    try {
      await _remoteDataSource.renameDevice(deviceId, newName);
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<String> issueChallenge(String token, String targetUserId) async {
    try {
      return await _remoteDataSource.createChallenge(targetUserId);
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<bool> verifyChallenge(
      String token, String challengeId, String signature) async {
    try {
      return await _remoteDataSource.verifyChallenge(challengeId, signature);
    } on NetworkException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  String generateVerificationPhrase() {
    return '';
  }

  @override
  VerificationState resolveState({
    required bool hasIdentity,
    required VerificationState current,
    required bool hasOutOfBandConfirmation,
  }) {
    return VerificationState.unknown;
  }

  IdentityFailure _toFailure(NetworkException e) {
    switch (e) {
      case UnauthorizedException():
        return NetworkIdentityFailure();
      case ServerErrorException():
        return ServerIdentityFailure(e.message);
      default:
        return UnknownIdentityFailure();
    }
  }
}
