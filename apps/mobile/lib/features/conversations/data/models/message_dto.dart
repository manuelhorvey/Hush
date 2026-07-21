class MessageDto {
  final String id;
  final String senderId;
  final String ciphertext;
  final String createdAt;

  const MessageDto({
    required this.id,
    required this.senderId,
    required this.ciphertext,
    required this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      ciphertext: json['ciphertext'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'ciphertext': ciphertext,
        'created_at': createdAt,
      };
}

class SendMessageRequest {
  final String ciphertext;

  const SendMessageRequest({required this.ciphertext});

  Map<String, dynamic> toJson() => {'ciphertext': ciphertext};
}
