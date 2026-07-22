import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hush_mobile/services/double_ratchet.dart';

/// Full round-trip tests of the Double Ratchet implementation.
///
/// These tests simulate two users (Alice & Bob) exchanging messages
/// without any network or storage layer — pure crypto validation.
void main() {
  late SimpleKeyPairData aliceIdentity;
  late SimpleKeyPairData bobIdentity;
  late List<int> sharedSecret;

  setUp(() async {
    final x25519 = X25519();

    // Each user generates a persistent X25519 keypair (their "identity key")
    final alicePair = await x25519.newKeyPair();
    aliceIdentity = await alicePair.extract();

    final bobPair = await x25519.newKeyPair();
    bobIdentity = await bobPair.extract();

    // Shared secret = DH(Alice_priv, Bob_pub) = DH(Bob_priv, Alice_pub)
    final secretA = await x25519.sharedSecretKey(
      keyPair: aliceIdentity,
      remotePublicKey: bobIdentity.publicKey,
    );
    final secretB = await x25519.sharedSecretKey(
      keyPair: bobIdentity,
      remotePublicKey: aliceIdentity.publicKey,
    );
    final bytesA = await secretA.extractBytes();
    final bytesB = await secretB.extractBytes();
    expect(bytesA, bytesB, reason: 'DH shared secrets must match');
    sharedSecret = bytesA;
  });

  group('Double Ratchet — first message (Alice → Bob)', () {
    test('encrypt and decrypt a single message', () async {
      // Alice sends the first message
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );

      const plaintext = 'Hello Bob!';
      final envelope = await DoubleRatchet.encrypt(aliceSession, plaintext);

      // Serialize and deserialize (simulate network transit)
      final wire = envelope.encode();
      final receivedEnvelope = RatchetEnvelope.decode(wire);

      // Bob receives and decrypts
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      final decrypted =
          await DoubleRatchet.decrypt(bobSession, receivedEnvelope);
      expect(decrypted, plaintext);
    });

    test('encrypt and decrypt multiple messages in order', () async {
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      const messages = ['Hello', 'How are you?', 'Are you there?'];
      final envelopes = <RatchetEnvelope>[];

      for (final msg in messages) {
        final env = await DoubleRatchet.encrypt(aliceSession, msg);
        envelopes.add(env);
      }

      for (var i = 0; i < messages.length; i++) {
        final decoded = await DoubleRatchet.decrypt(bobSession, envelopes[i]);
        expect(decoded, messages[i]);
      }
    });

    test('encrypt and decrypt out-of-order messages (skipped keys)', () async {
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      // Send three messages
      final env0 =
          await DoubleRatchet.encrypt(aliceSession, 'Message 0');
      final env1 =
          await DoubleRatchet.encrypt(aliceSession, 'Message 1');
      final env2 =
          await DoubleRatchet.encrypt(aliceSession, 'Message 2');

      // Receive in reverse order (2, 0, 1)
      final decrypted2 = await DoubleRatchet.decrypt(bobSession, env2);
      expect(decrypted2, 'Message 2');

      final decrypted0 = await DoubleRatchet.decrypt(bobSession, env0);
      expect(decrypted0, 'Message 0');

      final decrypted1 = await DoubleRatchet.decrypt(bobSession, env1);
      expect(decrypted1, 'Message 1');
    });
  });

  group('Double Ratchet — bidirectional (Alice ↔ Bob)', () {
    test('Alice sends first, Bob replies', () async {
      // Alice creates her session as initSender
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );

      // Bob creates his session as initReceiver
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      // Alice sends message 1
      final env1 = await DoubleRatchet.encrypt(aliceSession, 'Hi from Alice');
      final reply1 = await DoubleRatchet.decrypt(bobSession, env1);
      expect(reply1, 'Hi from Alice');

      // Bob replies (his session now has a sending chain after dhRatchetStep)
      final env2 = await DoubleRatchet.encrypt(bobSession, 'Hi back from Bob');
      final reply2 = await DoubleRatchet.decrypt(aliceSession, env2);
      expect(reply2, 'Hi back from Bob');

      // Alice sends another message (her session also has a sending chain)
      // and Bob decrypts it
      final env3 =
          await DoubleRatchet.encrypt(aliceSession, 'Message 3 from Alice');
      final reply3 = await DoubleRatchet.decrypt(bobSession, env3);
      expect(reply3, 'Message 3 from Alice');
    });

    test('session serialization roundtrip', () async {
      // Create sessions
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      // Send and decrypt one message to advance state
      final env =
          await DoubleRatchet.encrypt(aliceSession, 'Advance state');
      await DoubleRatchet.decrypt(bobSession, env);

      // Serialize Bob's session
      final bobJson = bobSession.toJson();
      final restoredBob = DoubleRatchetSession.fromJson(bobJson);

      // Send another message from Alice
      final env2 =
          await DoubleRatchet.encrypt(aliceSession, 'After serialization');
      final reply2 = await DoubleRatchet.decrypt(restoredBob, env2);
      expect(reply2, 'After serialization');
    });
  });

  group('Double Ratchet — multiple DH ratchets', () {
    test('three full turns (Alice→Bob→Alice→Bob→Alice→Bob)', () async {
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      const expected = [
        'A: msg 0',
        'B: reply 0',
        'A: msg 1',
        'B: reply 1',
        'A: msg 2',
        'B: reply 2',
      ];

      for (var i = 0; i < 3; i++) {
        // Alice sends
        final envA =
            await DoubleRatchet.encrypt(aliceSession, expected[i * 2]);
        final decA = await DoubleRatchet.decrypt(bobSession, envA);
        expect(decA, expected[i * 2]);

        // Bob sends
        final envB = await DoubleRatchet.encrypt(
            bobSession, expected[i * 2 + 1]);
        final decB = await DoubleRatchet.decrypt(aliceSession, envB);
        expect(decB, expected[i * 2 + 1]);
      }
    });
  });

  group('Double Ratchet — tamper resistance', () {
    test('tampered ciphertext causes decrypt to throw', () async {
      final aliceSession = await DoubleRatchet.initSender(
        sharedSecret,
        bobIdentity.publicKey.bytes,
      );
      final bobSession = await DoubleRatchet.initReceiver(
        sharedSecret,
        bobIdentity,
      );

      const plaintext = 'Secret message';
      var envelope =
          await DoubleRatchet.encrypt(aliceSession, plaintext);

      // Tamper with the base64 ciphertext — flip one character
      final tamperedCiphertext = envelope.ciphertextBase64.replaceFirst(
        envelope.ciphertextBase64[10],
        envelope.ciphertextBase64[10] == 'a' ? 'b' : 'a',
      );

      // Re-encode with tampered ciphertext
      envelope = RatchetEnvelope(
        envelope.header,
        tamperedCiphertext,
      );

      expect(
        DoubleRatchet.decrypt(bobSession, envelope),
        throwsA(isA<Exception>()),
      );
    });
  });
}
