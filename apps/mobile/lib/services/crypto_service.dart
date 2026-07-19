import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final FlutterSecureStorage _storage;

  CryptoService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _privateKeyKey = 'identity_private_key';
  static const _publicKeyKey = 'identity_public_key';

  Future<SimpleKeyPair> generateKeyPair() async {
    final ed25519 = Ed25519();
    final keyPair = await ed25519.newKeyPair();

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _storage.write(key: _privateKeyKey, value: base64Encode(privateKeyBytes));
    await _storage.write(key: _publicKeyKey, value: base64Encode(publicKey.bytes));

    return keyPair;
  }

  Future<String> getPublicKeyHex() async {
    final stored = await _storage.read(key: _publicKeyKey);
    if (stored == null) {
      final pair = await generateKeyPair();
      final publicKey = await pair.extractPublicKey();
      return bytesToHex(publicKey.bytes);
    }
    return bytesToHex(base64Decode(stored));
  }

  Future<bool> hasKeyPair() async {
    return await _storage.read(key: _privateKeyKey) != null;
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
