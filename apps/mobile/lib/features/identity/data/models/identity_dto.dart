class IdentityDto {
  final String id;
  final String displayName;
  final String? publicKey;
  final String? exchangeKey;
  final DateTime createdAt;

  const IdentityDto({
    required this.id,
    required this.displayName,
    this.publicKey,
    this.exchangeKey,
    required this.createdAt,
  });

  factory IdentityDto.fromJson(Map<String, dynamic> json) {
    return IdentityDto(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      publicKey: json['public_key'] as String?,
      exchangeKey: json['exchange_key'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'public_key': publicKey,
        'exchange_key': exchangeKey,
        'created_at': createdAt.toIso8601String(),
      };
}
