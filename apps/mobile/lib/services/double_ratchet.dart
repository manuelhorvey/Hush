import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class RatchetHeader {
  final List<int> dhPublicKey;
  final int previousChainLength;
  final int messageNumber;

  RatchetHeader({
    required this.dhPublicKey,
    required this.previousChainLength,
    required this.messageNumber,
  });

  Map<String, dynamic> toJson() => {
        'dh': base64Encode(dhPublicKey),
        'pn': previousChainLength,
        'n': messageNumber,
      };

  static RatchetHeader fromJson(Map<String, dynamic> json) => RatchetHeader(
        dhPublicKey: base64Decode(json['dh'] as String),
        previousChainLength: json['pn'] as int,
        messageNumber: json['n'] as int,
      );
}

class RatchetEnvelope {
  final RatchetHeader header;
  final String ciphertextBase64;

  RatchetEnvelope(this.header, this.ciphertextBase64);

  String encode() => jsonEncode({
        'h': header.toJson(),
        'c': ciphertextBase64,
      });

  static RatchetEnvelope decode(String wire) {
    final map = jsonDecode(wire) as Map<String, dynamic>;
    return RatchetEnvelope(
      RatchetHeader.fromJson(map['h'] as Map<String, dynamic>),
      map['c'] as String,
    );
  }
}

class _SkippedKey {
  final List<int> dhPublicKey;
  final int messageNumber;
  final List<int> messageKey;
  _SkippedKey(this.dhPublicKey, this.messageNumber, this.messageKey);
}

class DoubleRatchetSession {
  static const int maxSkippedKeys = 1000;

  SimpleKeyPairData dhSelf;
  List<int>? dhRemote;
  List<int> rootKey;
  List<int>? sendingChainKey;
  List<int>? receivingChainKey;
  int sendCount = 0;
  int receiveCount = 0;
  int previousSendCount = 0;
  final List<_SkippedKey> _skipped = [];

  DoubleRatchetSession({
    required this.dhSelf,
    required this.rootKey,
    this.dhRemote,
    this.sendingChainKey,
    this.receivingChainKey,
  });

  Map<String, dynamic> toJson() => {
        'dhSelfPriv': base64Encode(dhSelf.bytes),
        'dhSelfPub': base64Encode(dhSelf.publicKey.bytes),
        'dhRemote': dhRemote == null ? null : base64Encode(dhRemote!),
        'rootKey': base64Encode(rootKey),
        'ckS': sendingChainKey == null ? null : base64Encode(sendingChainKey!),
        'ckR':
            receivingChainKey == null ? null : base64Encode(receivingChainKey!),
        'ns': sendCount,
        'nr': receiveCount,
        'pn': previousSendCount,
        'skipped': _skipped
            .map((s) => {
                  'dh': base64Encode(s.dhPublicKey),
                  'n': s.messageNumber,
                  'k': base64Encode(s.messageKey),
                })
            .toList(),
      };

  static DoubleRatchetSession fromJson(Map<String, dynamic> json) {
    final session = DoubleRatchetSession(
      dhSelf: SimpleKeyPairData(
        base64Decode(json['dhSelfPriv'] as String),
        publicKey: SimplePublicKey(
          base64Decode(json['dhSelfPub'] as String),
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      ),
      rootKey: base64Decode(json['rootKey'] as String),
      dhRemote: json['dhRemote'] == null
          ? null
          : base64Decode(json['dhRemote'] as String),
      sendingChainKey:
          json['ckS'] == null ? null : base64Decode(json['ckS'] as String),
      receivingChainKey:
          json['ckR'] == null ? null : base64Decode(json['ckR'] as String),
    );
    session.sendCount = json['ns'] as int;
    session.receiveCount = json['nr'] as int;
    session.previousSendCount = json['pn'] as int;
    for (final s in (json['skipped'] as List)) {
      session._skipped.add(_SkippedKey(
        base64Decode(s['dh'] as String),
        s['n'] as int,
        base64Decode(s['k'] as String),
      ));
    }
    return session;
  }
}

class DoubleRatchet {
  static final _x25519 = X25519();
  static final _hmac = Hmac.sha256();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
  static final _aesGcm = AesGcm.with256bits();

  static Future<DoubleRatchetSession> initSender(
    List<int> sharedSecret,
    List<int> remoteIdentityX25519Public,
  ) async {
    final dhSelf = await _x25519.newKeyPair();
    final dhSelfData = await dhSelf.extract();
    final dhOut = await _dh(dhSelfData, remoteIdentityX25519Public);
    final (rk, ck) = await _kdfRootKey(sharedSecret, dhOut);
    return DoubleRatchetSession(
      dhSelf: dhSelfData,
      rootKey: rk,
      sendingChainKey: ck,
      dhRemote: remoteIdentityX25519Public,
    );
  }

  static Future<DoubleRatchetSession> initReceiver(
    List<int> sharedSecret,
    SimpleKeyPairData selfIdentityX25519KeyPair,
  ) async {
    return DoubleRatchetSession(
      dhSelf: selfIdentityX25519KeyPair,
      rootKey: sharedSecret,
    );
  }

  static Future<RatchetEnvelope> encrypt(
    DoubleRatchetSession s,
    String plaintext,
  ) async {
    if (s.sendingChainKey == null) {
      throw StateError(
          'No sending chain — session must receive at least one '
          'message before it can send (receiver after initReceiver).');
    }
    final (messageKey, nextChainKey) = await _kdfChainKey(s.sendingChainKey!);
    s.sendingChainKey = nextChainKey;

    final header = RatchetHeader(
      dhPublicKey: s.dhSelf.publicKey.bytes,
      previousChainLength: s.previousSendCount,
      messageNumber: s.sendCount,
    );
    s.sendCount += 1;

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(messageKey),
    );
    final combined = [
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
    return RatchetEnvelope(header, base64Encode(combined));
  }

  static Future<String> decrypt(
    DoubleRatchetSession s,
    RatchetEnvelope envelope,
  ) async {
    final header = envelope.header;

    final skippedKey = _trySkippedKey(s, header);
    if (skippedKey != null) {
      return _decryptWith(skippedKey, envelope.ciphertextBase64);
    }

    if (s.dhRemote == null || !_bytesEqual(s.dhRemote!, header.dhPublicKey)) {
      if (s.dhRemote != null && s.receivingChainKey != null) {
        await _skipMessageKeys(s, header.previousChainLength);
      }
      await _dhRatchetStep(s, header.dhPublicKey);
    }

    await _skipMessageKeys(s, header.messageNumber);

    final (messageKey, nextChainKey) =
        await _kdfChainKey(s.receivingChainKey!);
    s.receivingChainKey = nextChainKey;
    s.receiveCount += 1;

    return _decryptWith(messageKey, envelope.ciphertextBase64);
  }

  static Future<List<int>> _dh(
      SimpleKeyPairData self, List<int> remotePublic) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: self,
      remotePublicKey:
          SimplePublicKey(remotePublic, type: KeyPairType.x25519),
    );
    return shared.extractBytes();
  }

  static Future<(List<int>, List<int>)> _kdfRootKey(
      List<int> rootKey, List<int> dhOut) async {
    final output = await _hkdf.deriveKey(
      secretKey: SecretKey(dhOut),
      nonce: rootKey,
      info: utf8.encode('Hush_DR_Root'),
    );
    final bytes = await output.extractBytes();
    return (bytes.sublist(0, 32), bytes.sublist(32, 64));
  }

  static Future<(List<int>, List<int>)> _kdfChainKey(
      List<int> chainKey) async {
    final msgKeyMac = await _hmac.calculateMac(
      [0x01],
      secretKey: SecretKey(chainKey),
    );
    final nextChainMac = await _hmac.calculateMac(
      [0x02],
      secretKey: SecretKey(chainKey),
    );
    return (msgKeyMac.bytes, nextChainMac.bytes);
  }

  static Future<void> _dhRatchetStep(
      DoubleRatchetSession s, List<int> newRemotePublic) async {
    s.previousSendCount = s.sendCount;
    s.sendCount = 0;
    s.receiveCount = 0;
    s.dhRemote = newRemotePublic;

    final dhOutRecv = await _dh(s.dhSelf, newRemotePublic);
    final (rk1, ckR) = await _kdfRootKey(s.rootKey, dhOutRecv);
    s.rootKey = rk1;
    s.receivingChainKey = ckR;

    final newSelf = await _x25519.newKeyPair();
    s.dhSelf = await newSelf.extract();
    final dhOutSend = await _dh(s.dhSelf, newRemotePublic);
    final (rk2, ckS) = await _kdfRootKey(s.rootKey, dhOutSend);
    s.rootKey = rk2;
    s.sendingChainKey = ckS;
  }

  static Future<void> _skipMessageKeys(
      DoubleRatchetSession s, int until) async {
    if (s.receivingChainKey == null) return;
    if (until - s.receiveCount > DoubleRatchetSession.maxSkippedKeys) {
      s.receiveCount = until;
      return;
    }
    while (s.receiveCount < until) {
      final (messageKey, nextChainKey) =
          await _kdfChainKey(s.receivingChainKey!);
      s.receivingChainKey = nextChainKey;
      s._skipped.add(_SkippedKey(s.dhRemote!, s.receiveCount, messageKey));
      if (s._skipped.length > DoubleRatchetSession.maxSkippedKeys) {
        s._skipped.removeAt(0);
      }
      s.receiveCount += 1;
    }
  }

  static List<int>? _trySkippedKey(
      DoubleRatchetSession s, RatchetHeader header) {
    for (var i = 0; i < s._skipped.length; i++) {
      final sk = s._skipped[i];
      if (sk.messageNumber == header.messageNumber &&
          _bytesEqual(sk.dhPublicKey, header.dhPublicKey)) {
        s._skipped.removeAt(i);
        return sk.messageKey;
      }
    }
    return null;
  }

  static Future<String> _decryptWith(
      List<int> messageKey, String ciphertextBase64) async {
    final decoded = base64Decode(ciphertextBase64);
    final nonce = decoded.sublist(0, 12);
    final ct = decoded.sublist(12, decoded.length - 16);
    final mac = decoded.sublist(decoded.length - 16);
    final plaintext = await _aesGcm.decrypt(
      SecretBox(ct, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(messageKey),
    );
    return utf8.decode(plaintext);
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
