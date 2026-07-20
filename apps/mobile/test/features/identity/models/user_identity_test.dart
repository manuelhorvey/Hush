import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/user_identity.dart';
import 'package:hush_mobile/features/identity/models/verification_state.dart';

void main() {
  group('UserIdentity', () {
    final now = DateTime.now();
    final identity = UserIdentity(
      id: 'user-1',
      displayName: 'Alex',
      createdAt: now,
    );

    test('initializes with correct values', () {
      expect(identity.id, 'user-1');
      expect(identity.displayName, 'Alex');
      expect(identity.verificationState, VerificationState.unknown);
      expect(identity.createdAt, now);
    });

    test('initials returns single letter for single name', () {
      expect(identity.initials, 'A');
    });

    test('initials returns two letters for full name', () {
      final full = UserIdentity(
        id: 'u2',
        displayName: 'Alex River',
        createdAt: now,
      );
      expect(full.initials, 'AR');
    });

    test('copyWith updates verification state', () {
      final updated = identity.copyWith(
        verificationState: VerificationState.verified,
      );
      expect(updated.verificationState, VerificationState.verified);
      expect(updated.id, identity.id);
      expect(updated.displayName, identity.displayName);
    });

    test('initials returns question mark for empty name', () {
      final empty = UserIdentity(
        id: 'u3',
        displayName: '',
        createdAt: now,
      );
      expect(empty.initials, '?');
    });
  });
}
