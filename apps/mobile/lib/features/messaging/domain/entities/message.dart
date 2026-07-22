import 'message_status.dart';

/// Represents a single message within a conversation.
///
/// Follows Hush's privacy principles:
/// - Content is the decrypted plaintext
/// - Status reflects delivery, not read state
/// - No read receipts, no seen status, no typing indicators
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  /// Whether this message was sent by the current user.
  bool isOwn(String currentUserId) => senderId == currentUserId;

  /// Human-readable relative time string.
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${createdAt.month}/${createdAt.day}';
  }

  /// Formatted time string (HH:MM).
  String get timeString {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Accessibility label for screen readers.
  String get accessibilityLabel {
    final time = timeString;
    final statusLabel = status != MessageStatus.sent ? ', ${status.label}' : '';
    return 'Message from $senderName. $content. Sent $time.$statusLabel';
  }

  /// Key for grouping messages by date.
  String get dateGroupKey {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(msgDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'Earlier this week';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }

  /// Create a copy with updated fields.
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'Message(id=$id, sender=$senderName, status=${status.label}, content=${content.length > 30 ? "${content.substring(0, 30)}..." : content})';
}
