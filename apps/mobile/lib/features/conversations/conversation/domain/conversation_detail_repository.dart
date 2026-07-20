import '../models/message.dart';

abstract class ConversationDetailRepository {
  Future<List<Message>> getMessages(String conversationId);
  Future<bool> sendMessage(String conversationId, String content);
  Future<bool> completeConversation(String conversationId);
  Future<bool> destroyConversation(String conversationId);
  String getStatus(String conversationId);
}
