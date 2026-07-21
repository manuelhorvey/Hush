import '../models/conversation.dart';

abstract interface class ConversationRepository {
  Future<List<Conversation>> listConversations();
  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  });
  Future<Conversation> completeConversation(String id);
  Future<void> destroyConversation(String id);
  Future<List<({String id, String username})>> searchUsers(String query);
}
