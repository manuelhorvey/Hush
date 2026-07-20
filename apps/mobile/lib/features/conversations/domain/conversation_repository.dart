import '../models/conversation.dart';

abstract interface class ConversationRepository {
  Future<List<Conversation>> listConversations();
  Future<Conversation> createConversation({
    required String participantName,
    required String participantId,
  });
  Conversation generateMockConversation({ConversationLifecycle? lifecycle});
  List<Conversation> generateMockData();
}
