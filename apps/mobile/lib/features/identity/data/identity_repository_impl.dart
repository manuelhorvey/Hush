import 'dart:math';

import '../../../services/api_client.dart';
import '../../../services/identity_service.dart';
import '../domain/identity_failure.dart';
import '../domain/identity_repository.dart';
import '../models/device_identity.dart';
import '../models/user_identity.dart';
import '../models/verification_state.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  final IdentityService _service;
  final Random _rng;

  static const _verificationWords = <String>[
    'BLUE', 'RED', 'GREEN', 'GOLD', 'LAKE', 'RIVER',
    'MOON', 'STAR', 'WIND', 'FIRE', 'DUNE', 'MIST',
    'PEAK', 'VALE', 'REEF', 'FROST', 'BELL', 'WING',
    'RAIN', 'STONE', 'CLOUD', 'LIGHT', 'STORM', 'WAVE',
    'LEAF', 'REED', 'SAND', 'BROOK', 'ECHO', 'NORTH',
  ];

  IdentityRepositoryImpl({
    required IdentityService service,
    Random? random,
  })  : _service = service,
        _rng = random ?? Random.secure();

  @override
  Future<UserIdentity> createIdentity({
    required String token,
    required String displayName,
  }) async {
    try {
      final deviceInfo = await _service.registerDevice(
        token,
        displayName,
        '',
      );
      return UserIdentity(
        id: deviceInfo.id,
        displayName: displayName,
        createdAt:
            DateTime.tryParse(deviceInfo.createdAt) ?? DateTime.now(),
        verificationState: VerificationState.unknown,
        verificationPhrase: generateVerificationPhrase(),
      );
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  @override
  Future<List<DeviceIdentity>> listDevices(String token) async {
    try {
      final devices = await _service.listDevices(token);
      return devices
          .map((d) => DeviceIdentity(
                id: d.id,
                deviceName: d.deviceName,
                createdAt:
                    DateTime.tryParse(d.createdAt) ?? DateTime.now(),
                trustStatus: TrustStatus.trusted,
              ))
          .toList();
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  @override
  Future<void> confirmDevice(String token, String deviceId) async {
    try {
      await _service.storeExchangeKey(token, deviceId);
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  @override
  Future<void> removeDevice(String token, String deviceId) async {
    try {
      await _service.storeExchangeKey(token, '');
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  @override
  Future<void> renameDevice(
    String token,
    String deviceId,
    String newName,
  ) async {
    return;
  }

  @override
  Future<String> issueChallenge(String token, String targetUserId) async {
    try {
      final result = await _service.createChallenge(token, targetUserId);
      return result['id'] as String? ?? '';
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  @override
  Future<bool> verifyChallenge(
    String token,
    String challengeId,
    String signature,
  ) async {
    try {
      return await _service.verifyChallenge(token, challengeId, signature);
    } on ApiException catch (e) {
      throw ServerIdentityFailure(e.message);
    } catch (_) {
      throw const NetworkIdentityFailure();
    }
  }

  static const int _phraseWordCount = 2;

  @override
  String generateVerificationPhrase() {
    final picked = List<String>.generate(
      _phraseWordCount,
      (_) => _verificationWords[_rng.nextInt(_verificationWords.length)],
    );
    final number = _rng.nextInt(90) + 10;
    return '${picked.join(' ')} $number';
  }

  @override
  VerificationState resolveState({
    required bool hasIdentity,
    required VerificationState current,
    required bool hasOutOfBandConfirmation,
  }) {
    if (!hasIdentity) return VerificationState.unknown;
    if (current == VerificationState.verified &&
        !hasOutOfBandConfirmation) {
      return VerificationState.warning;
    }
    return current;
  }
}

IdentityFailure toFailure(Object e) {
  if (e is IdentityFailure) return e;
  if (e is ApiException) return ServerIdentityFailure(e.message);
  return const NetworkIdentityFailure();
}
