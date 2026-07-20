import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/identity/models/verification_state.dart';

void main() {
  group('VerificationState', () {
    test('unknown has correct label', () {
      expect(VerificationState.unknown.label, 'Not verified yet');
    });

    test('pending has correct label', () {
      expect(VerificationState.pending.label, 'Waiting for verification');
    });

    test('verified has correct label', () {
      expect(VerificationState.verified.label, 'Verified');
    });

    test('warning has correct label', () {
      expect(VerificationState.warning.label, 'Verification changed');
    });

    test('all states have descriptions', () {
      for (final state in VerificationState.values) {
        expect(state.description.isNotEmpty, isTrue);
      }
    });
  });
}
