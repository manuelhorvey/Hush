/// Represents a real-time event for a conversation.
///
/// These events are received over WebSocket and drive the UI updates.
/// Event types follow the conversation lifecycle:
///   Created → Active → Completed → Closed → Destroyed
class ConversationEvent {
  final ConversationEventType type;
  final String conversationId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const ConversationEvent({
    required this.type,
    required this.conversationId,
    this.data,
    required this.timestamp,
  });

  /// Parse a raw WebSocket event into a typed ConversationEvent.
  ///
  /// Expected JSON format:
  /// ```json
  /// { "type": "message.created", "conversation_id": "...", "data": { ... } }
  /// ```
  factory ConversationEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = ConversationEventType.values.firstWhere(
      (t) => t.jsonValue == typeStr,
      orElse: () => ConversationEventType.unknown,
    );

    return ConversationEvent(
      type: type,
      conversationId: json['conversation_id'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.jsonValue,
        'conversation_id': conversationId,
        'data': data,
      };

  @override
  String toString() =>
      'ConversationEvent(${type.jsonValue}, conv=$conversationId)';
}

enum ConversationEventType {
  /// A new message was created in the conversation
  messageCreated('message.created'),

  /// An existing message was updated (e.g., status change)
  messageUpdated('message.updated'),

  /// A message failed to send
  messageFailed('message.failed'),

  /// The conversation was completed
  conversationCompleted('conversation.completed'),

  /// The conversation was closed
  conversationClosed('conversation.closed'),

  /// The conversation was destroyed
  conversationDestroyed('conversation.destroyed'),

  /// Unknown event type (for forward compatibility)
  unknown('unknown');

  final String jsonValue;

  const ConversationEventType(this.jsonValue);
}
