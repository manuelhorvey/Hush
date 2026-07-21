class ConversationDto {
  final String id;
  final List<ParticipantDto> participants;
  final String status;
  final String? expiresAt;
  final String createdAt;
  final bool? isVerified;

  const ConversationDto({
    required this.id,
    required this.participants,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    this.isVerified,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    final list = (json['participants'] as List<dynamic>)
        .map((p) => ParticipantDto.fromJson(p as Map<String, dynamic>))
        .toList();
    return ConversationDto(
      id: json['id'] as String,
      participants: list,
      status: json['status'] as String? ?? 'active',
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String,
      isVerified: json['is_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participants': participants.map((p) => p.toJson()).toList(),
        'status': status,
        'expires_at': expiresAt,
        'created_at': createdAt,
        'is_verified': isVerified,
      };
}

class ParticipantDto {
  final String userId;
  final String username;

  const ParticipantDto({required this.userId, required this.username});

  factory ParticipantDto.fromJson(Map<String, dynamic> json) {
    return ParticipantDto(
      userId: json['user_id'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
      };
}
