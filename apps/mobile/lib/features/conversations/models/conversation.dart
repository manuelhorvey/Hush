enum ConversationLifecycle {
  active,
  waiting,
  completing,
  closed,
  warning;

  String get label {
    switch (this) {
      case ConversationLifecycle.active:
        return 'Active';
      case ConversationLifecycle.waiting:
        return 'Waiting';
      case ConversationLifecycle.completing:
        return 'Completing';
      case ConversationLifecycle.closed:
        return 'Closed';
      case ConversationLifecycle.warning:
        return 'Warning';
    }
  }

  String get description {
    switch (this) {
      case ConversationLifecycle.active:
        return 'Moment active';
      case ConversationLifecycle.waiting:
        return 'Waiting for response';
      case ConversationLifecycle.completing:
        return 'Moment ending';
      case ConversationLifecycle.closed:
        return 'Moment ended';
      case ConversationLifecycle.warning:
        return 'Needs attention';
    }
  }

  bool get isOpen => this == ConversationLifecycle.active ||
      this == ConversationLifecycle.waiting;
}

class ConversationParticipant {
  final String id;
  final String displayName;

  const ConversationParticipant({
    required this.id,
    required this.displayName,
  });
}

class Conversation {
  final String id;
  final List<ConversationParticipant> participants;
  final ConversationLifecycle lifecycle;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isVerified;
  final String? currentUserId;

  const Conversation({
    required this.id,
    required this.participants,
    this.lifecycle = ConversationLifecycle.active,
    required this.createdAt,
    this.completedAt,
    this.isVerified = false,
    this.currentUserId,
  });

  List<ConversationParticipant> get otherParticipants {
    if (currentUserId == null) return participants;
    return participants.where((p) => p.id != currentUserId).toList();
  }

  String get displayName {
    final others = otherParticipants;
    if (others.isEmpty) return participants.firstOrNull?.displayName ?? 'Unknown';
    if (others.length == 1) return others.first.displayName;
    final names = others.map((p) => p.displayName).toList();
    return '${names.first} +${names.length - 1}';
  }

  String? get firstOtherParticipantName {
    return otherParticipants.firstOrNull?.displayName;
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}';
  }

  String get completedRelativeTime {
    if (completedAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(completedAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${completedAt!.month}/${completedAt!.day}';
  }

  String get accessibilityLabel {
    final name = displayName;
    final lifecycleInfo = lifecycle.description;
    final security = isVerified ? 'Verified.' : 'Private.';
    return '$name. $security $lifecycleInfo.';
  }
}
