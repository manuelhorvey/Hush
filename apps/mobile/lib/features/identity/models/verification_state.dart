enum VerificationState {
  unknown,
  pending,
  verified,
  warning;

  String get label {
    switch (this) {
      case VerificationState.unknown:
        return 'Not verified yet';
      case VerificationState.pending:
        return 'Waiting for verification';
      case VerificationState.verified:
        return 'Verified';
      case VerificationState.warning:
        return 'Verification changed';
    }
  }

  String get description {
    switch (this) {
      case VerificationState.unknown:
        return 'Verification helps you confirm you are speaking with the right person.';
      case VerificationState.pending:
        return 'Waiting for the other person to complete verification.';
      case VerificationState.verified:
        return 'You have confirmed this is the right person.';
      case VerificationState.warning:
        return 'The verification information has changed. Review before continuing.';
    }
  }
}
