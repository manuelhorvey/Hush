import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';

/// Data Transfer Object for message API responses.
///
/// Handles serialization between the JSON API format and the domain [Message].
class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String ciphertext;
  final String createdAt;
  final String status;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.ciphertext,
    required this.createdAt,
    this.status = 'sent',
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? json['username'] as String? ?? 'Unknown',
      ciphertext: json['ciphertext'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      status: json['status'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'ciphertext': ciphertext,
        'created_at': createdAt,
        'status': status,
      };

  /// Convert to domain [Message] with decrypted content.
  Message toDomain({
    required String content,
    required MessageStatus messageStatus,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      status: messageStatus,
    );
  }

}

/// Request DTO for sending a message.
class SendMessageRequest {
  final String ciphertext;

  const SendMessageRequest({required this.ciphertext});

  Map<String, dynamic> toJson() => {'ciphertext': ciphertext};
}
