import '../../../../services/messaging_service.dart';
import '../models/message_dto.dart';

/// Remote data source for message operations.
///
/// Communicates with the backend API for message CRUD.
/// Does NOT handle WebSocket events — that's the repository's job.
class MessageRemoteDataSource {
  final MessagingService _messaging;

  MessageRemoteDataSource({required MessagingService messaging})
      : _messaging = messaging;

  /// Send a ciphertext message to the server.
  Future<MessageDto> sendMessage({
    required String token,
    required String conversationId,
    required String ciphertext,
  }) async {
    final info = await _messaging.sendMessage(token, conversationId, ciphertext);
    return MessageDto(
      id: info.id,
      conversationId: conversationId,
      senderId: info.senderId,
      senderName: '',
      ciphertext: info.ciphertext,
      createdAt: info.createdAt,
      status: 'sent',
    );
  }

  /// Fetch messages from the server.
  Future<List<MessageDto>> listMessages({
    required String token,
    required String conversationId,
  }) async {
    final infos = await _messaging.listMessages(token, conversationId);
    return infos.map((info) => MessageDto(
      id: info.id,
      conversationId: conversationId,
      senderId: info.senderId,
      senderName: '',
      ciphertext: info.ciphertext,
      createdAt: info.createdAt,
      status: 'sent',
    )).toList();
  }

  /// Fetch participants for a conversation (for name resolution).
  Future<List<ParticipantInfo>> getParticipants({
    required String token,
    required String conversationId,
  }) async {
    return _messaging.getParticipants(token, conversationId);
  }

  /// Fetch a single participant's info for name resolution.
  Future<ParticipantInfo?> getParticipant({
    required String token,
    required String conversationId,
    required String userId,
  }) async {
    final participants = await _messaging.getParticipants(token, conversationId);
    return participants.where((p) => p.userId == userId).firstOrNull;
  }
}
