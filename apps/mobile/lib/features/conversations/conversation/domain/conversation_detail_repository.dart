import 'dart:async';

import '../models/message.dart';

enum DetailRepositoryStatus { active, completed, destroyed }

abstract class ConversationDetailRepository {
  Future<List<Message>> getMessages(String conversationId);
  Future<bool> sendMessage(String conversationId, String ciphertext);
  Future<bool> completeConversation(String conversationId);
  Future<bool> destroyConversation(String conversationId);
  Future<DetailRepositoryStatus> getStatus(String conversationId);
  Stream<Message> messageStream(String conversationId);
  Future<void> dispose();
  Future<void> flushPendingMessages(String conversationId);
}
