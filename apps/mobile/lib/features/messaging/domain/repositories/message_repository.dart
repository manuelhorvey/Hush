import 'dart:async';

import '../entities/connection_state.dart';
import '../entities/conversation_event.dart';
import '../entities/message.dart';

/// Repository for message operations.
///
/// This is the single source of truth for message data.
/// All message operations go through this repository.
///
/// Architecture flow:
///   UI → Provider → Repository → Remote Data Source / WebSocket
abstract class MessageRepository {
  /// Send a message to a conversation.
  ///
  /// Returns the [Message] with the server-assigned ID and status.
  /// Throws [MessageSendException] on failure.
  Future<Message> sendMessage({
    required String conversationId,
    required String plaintext,
    required String currentUserId,
    required String currentUserName,
  });

  /// Get messages for a conversation, optionally paginated.
  ///
  /// [limit] controls page size. [before] is the ID of the last known
  /// message — pass it to load older messages (cursor-based pagination).
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  });

  /// Stream of messages for a conversation (real-time updates).
  Stream<Message> observeMessages(String conversationId);

  /// Stream of conversation events (status changes, etc.).
  Stream<ConversationEvent> observeEvents(String conversationId);

  /// Retry sending a failed message.
  Future<Message> retryMessage(
    String conversationId,
    Message failedMessage,
  );

  /// Mark all pending messages in a conversation as failed.
  Future<void> failPendingMessages(String conversationId);

  /// Get the current connection state.
  Stream<ConnectionState> observeConnectionState();
}

/// Exception thrown when message sending fails.
class MessageSendException implements Exception {
  final String message;
  final String? conversationId;

  const MessageSendException(this.message, {this.conversationId});

  @override
  String toString() => 'MessageSendException: $message';
}
