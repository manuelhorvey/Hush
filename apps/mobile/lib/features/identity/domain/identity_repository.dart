import '../models/device_identity.dart';
import '../models/user_identity.dart';
import '../models/verification_state.dart';

abstract interface class IdentityRepository {
  Future<UserIdentity> createIdentity({
    required String token,
    required String displayName,
  });

  Future<List<DeviceIdentity>> listDevices(String token);

  Future<void> confirmDevice(String token, String deviceId);

  Future<void> removeDevice(String token, String deviceId);

  Future<void> renameDevice(
    String token,
    String deviceId,
    String newName,
  );

  Future<String> issueChallenge(String token, String targetUserId);

  Future<bool> verifyChallenge(String token, String challengeId, String signature);

  String generateVerificationPhrase();

  VerificationState resolveState({
    required bool hasIdentity,
    required VerificationState current,
    required bool hasOutOfBandConfirmation,
  });
}
