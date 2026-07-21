import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../services/api_client.dart';
import '../../../services/crypto_service.dart';
import '../../../services/identity_service.dart';
import '../models/device_identity.dart';
import '../models/user_identity.dart';
import '../models/verification_state.dart';

enum IdentityCreateStatus { idle, loading, success, error }

class IdentityProvider extends ChangeNotifier {
  final IdentityService _identity;
  final CryptoService _crypto;

  IdentityProvider({
    required this._identity,
    required this._crypto,
  });

  UserIdentity? _userIdentity;
  List<DeviceIdentity> _devices = [];
  IdentityCreateStatus _createStatus = IdentityCreateStatus.idle;
  String? _errorMessage;
  bool _loading = true;

  UserIdentity? get userIdentity => _userIdentity;
  List<DeviceIdentity> get devices => _devices;
  IdentityCreateStatus get createStatus => _createStatus;
  String? get errorMessage => _errorMessage;
  bool get loading => _loading;

  void setSessionIdentity({
    required String userId,
    required String username,
  }) {
    _userIdentity = UserIdentity(
      id: userId,
      displayName: username,
      createdAt: DateTime.now(),
      verificationState: VerificationState.unknown,
      verificationPhrase: _generateVerificationPhrase(),
    );
    _loading = false;
    notifyListeners();
  }

  String _generateVerificationPhrase() {
    const words = [
      'BLUE', 'RED', 'GREEN', 'GOLD', 'LAKE', 'RIVER',
      'MOON', 'STAR', 'WIND', 'FIRE', 'DUNE', 'MIST',
      'PEAK', 'VALE', 'REEF', 'FROST', 'BELL', 'WING',
    ];
    final rng = Random();
    final a = words[rng.nextInt(words.length)];
    final b = words[rng.nextInt(words.length)];
    final num = rng.nextInt(90) + 10;
    return '$a $b $num';
  }

  Future<void> createIdentity(
    String token,
    String displayName,
  ) async {
    _createStatus = IdentityCreateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final publicKey = await _crypto.getPublicKeyHex();

      await _identity.registerDevice(
        token,
        displayName,
        publicKey,
      );

      final x25519PubKey = await _crypto.getX25519PublicKeyBase64();
      await _identity.storeExchangeKey(token, x25519PubKey);

      _userIdentity = UserIdentity(
        id: '',
        displayName: displayName,
        createdAt: DateTime.now(),
        verificationState: VerificationState.unknown,
        verificationPhrase: _generateVerificationPhrase(),
      );

      _createStatus = IdentityCreateStatus.success;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _createStatus = IdentityCreateStatus.error;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Connection failed. Check that the server is running.';
      _createStatus = IdentityCreateStatus.error;
      notifyListeners();
    }
  }

  Future<void> loadDevices(String token) async {
    try {
      final rawDevices = await _identity.listDevices(token);
      _devices = rawDevices.map((d) {
        return DeviceIdentity(
          id: d.id,
          deviceName: d.deviceName,
          createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
          trustStatus: TrustStatus.trusted,
        );
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  void setVerificationState(VerificationState state) {
    if (_userIdentity != null) {
      _userIdentity = _userIdentity!.copyWith(verificationState: state);
      notifyListeners();
    }
  }

  void requestVerification() {
    if (_userIdentity != null) {
      _userIdentity = _userIdentity!.copyWith(
        verificationState: VerificationState.pending,
        verificationPhrase: _generateVerificationPhrase(),
      );
      notifyListeners();
    }
  }

  void confirmVerification() {
    if (_userIdentity != null) {
      _userIdentity = _userIdentity!.copyWith(
        verificationState: VerificationState.verified,
      );
      notifyListeners();
    }
  }

  String get verificationPhrase =>
      _userIdentity?.verificationPhrase ?? _generateVerificationPhrase();
}
