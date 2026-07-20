enum MessageStatus { sending, sent, failed }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${createdAt.month}/${createdAt.day}';
  }

  String get timeString {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get accessibilityLabel {
    final time = timeString;
    return 'Message from $senderName. $content. Sent $time.';
  }

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

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(msgDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}
