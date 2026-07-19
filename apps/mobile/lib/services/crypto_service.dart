import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final FlutterSecureStorage _storage;

  CryptoService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _privateKeyKey = 'identity_private_key';
  static const _publicKeyKey = 'identity_public_key';
  static const _x25519PrivateKey = 'x25519_private_key';
  static const _x25519PublicKey = 'x25519_public_key';

  Future<SimpleKeyPair> generateKeyPair() async {
    final ed25519 = Ed25519();
    final keyPair = await ed25519.newKeyPair();

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _storage.write(
        key: _privateKeyKey, value: base64Encode(privateKeyBytes));
    await _storage.write(
        key: _publicKeyKey, value: base64Encode(publicKey.bytes));

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

  Future<SimpleKeyPairData> generateX25519KeyPair() async {
    final x25519 = X25519();
    final keyPair = await x25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _storage.write(
        key: _x25519PrivateKey, value: base64Encode(privateKeyBytes));
    await _storage.write(
        key: _x25519PublicKey, value: base64Encode(publicKey.bytes));

    return SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(publicKey.bytes, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
  }

  Future<String> getX25519PublicKeyBase64() async {
    final stored = await _storage.read(key: _x25519PublicKey);
    if (stored == null) {
      final keyPair = await generateX25519KeyPair();
      return base64Encode(keyPair.publicKey.bytes);
    }
    return stored;
  }

  Future<SimpleKeyPairData> _loadX25519KeyPair() async {
    final priv = await _storage.read(key: _x25519PrivateKey);
    final pub = await _storage.read(key: _x25519PublicKey);
    if (priv == null || pub == null) {
      return await generateX25519KeyPair();
    }
    return SimpleKeyPairData(
      base64Decode(priv),
      publicKey: SimplePublicKey(base64Decode(pub), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
  }

  Future<List<int>> deriveSharedSecret(String otherPublicKeyBase64) async {
    final myKeyPair = await _loadX25519KeyPair();
    final x25519 = X25519();

    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: SimplePublicKey(
        base64Decode(otherPublicKeyBase64),
        type: KeyPairType.x25519,
      ),
    );

    return await sharedSecret.extractBytes();
  }

  Future<List<int>> _deriveAesKey(List<int> sharedSecret) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(sharedSecret);
    return hash.bytes;
  }

  Future<String> encryptWithSharedKey(
      String plaintext, List<int> sharedSecret) async {
    final aesKeyBytes = await _deriveAesKey(sharedSecret);
    final aesKey = SecretKey(aesKeyBytes);

    final aesGcm = AesGcm.with256bits();
    final secretBox = await aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
    );

    final combined = [
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
    return base64Encode(combined);
  }

  Future<String> decryptWithSharedKey(
      String ciphertext, List<int> sharedSecret) async {
    final aesKeyBytes = await _deriveAesKey(sharedSecret);
    final aesKey = SecretKey(aesKeyBytes);

    final decoded = base64Decode(ciphertext);
    final nonce = decoded.sublist(0, 12);
    final ct = decoded.sublist(12, decoded.length - 16);
    final mac = decoded.sublist(decoded.length - 16);

    final aesGcm = AesGcm.with256bits();
    final secretBox = SecretBox(
      ct,
      nonce: nonce,
      mac: Mac(mac),
    );

    final plaintext = await aesGcm.decrypt(
      secretBox,
      secretKey: aesKey,
    );

    return utf8.decode(plaintext);
  }

  List<int> generateGroupKey() {
    final rng = Random.secure();
    return List<int>.generate(32, (_) => rng.nextInt(256));
  }

  Future<String> encryptGroupKey(
      List<int> groupKey, String otherPublicKeyBase64) async {
    final sharedSecret = await deriveSharedSecret(otherPublicKeyBase64);
    return await encryptWithSharedKey(
        base64Encode(groupKey), sharedSecret);
  }

  Future<List<int>> decryptGroupKey(
      String encryptedGroupKey, String otherPublicKeyBase64) async {
    final sharedSecret = await deriveSharedSecret(otherPublicKeyBase64);
    final decoded = await decryptWithSharedKey(encryptedGroupKey, sharedSecret);
    return base64Decode(decoded);
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
