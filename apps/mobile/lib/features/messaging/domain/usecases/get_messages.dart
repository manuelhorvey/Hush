import '../entities/message.dart';
import '../repositories/message_repository.dart';

/// Use case for retrieving messages.
///
/// Supports both initial load and pagination.
class GetMessages {
  final MessageRepository _repository;

  GetMessages(this._repository);

  /// Get messages for a conversation.
  ///
  /// [limit] controls page size. [before] is the cursor for pagination
  /// (the ID of the first message in the current view).
  Future<List<Message>> call(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    return _repository.getMessages(
      conversationId,
      limit: limit,
      before: before,
    );
  }
}
