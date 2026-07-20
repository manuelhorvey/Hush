import 'verification_state.dart';

class UserIdentity {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final VerificationState verificationState;
  final String? verificationPhrase;

  const UserIdentity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.verificationState = VerificationState.unknown,
    this.verificationPhrase,
  });

  UserIdentity copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    VerificationState? verificationState,
    String? verificationPhrase,
  }) {
    return UserIdentity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      verificationState: verificationState ?? this.verificationState,
      verificationPhrase: verificationPhrase ?? this.verificationPhrase,
    );
  }

  String get initials {
    if (displayName.isEmpty) return '?';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
