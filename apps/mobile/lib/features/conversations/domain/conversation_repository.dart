import '../models/conversation.dart';

abstract interface class ConversationRepository {
  Future<List<Conversation>> listConversations();
  Conversation generateMockConversation({ConversationLifecycle? lifecycle});
  List<Conversation> generateMockData();
}
