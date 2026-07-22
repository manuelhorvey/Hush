import '../entities/message.dart';
import '../repositories/message_repository.dart';

/// Use case for sending a message.
///
/// Encapsulates the send logic with validation and error handling.
class SendMessage {
  final MessageRepository _repository;

  SendMessage(this._repository);

  /// Send a message to a conversation.
  ///
  /// Returns the [Message] with server-assigned ID.
  /// Throws [MessageSendException] on failure.
  Future<Message> call({
    required String conversationId,
    required String plaintext,
    required String currentUserId,
    required String currentUserName,
  }) async {
    if (plaintext.trim().isEmpty) {
      throw const MessageSendException('Cannot send empty message.');
    }

    return _repository.sendMessage(
      conversationId: conversationId,
      plaintext: plaintext,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    );
  }
}
