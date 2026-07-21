import '../../../../core/config/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/conversation_dto.dart';
import '../models/message_dto.dart';

abstract class ConversationRemoteDataSource {
  Future<List<ConversationDto>> getConversations();
  Future<ConversationDto> createConversation(
    List<String> participantIds, {
    Map<String, String>? encryptedKeys,
  });
  Future<void> completeConversation(String conversationId);
  Future<void> destroyConversation(String conversationId);
  Future<List<MessageDto>> getMessages(String conversationId);
  Future<MessageDto> sendMessage(
      String conversationId, String ciphertext);
  Future<String> getGroupKey(String conversationId);
  Future<List<ParticipantDto>> getParticipants(String conversationId);
  Future<List<UserDto>> searchUsers(String query);
}

class UserDto {
  final String id;
  final String username;

  const UserDto({required this.id, required this.username});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      username: json['username'] as String,
    );
  }
}

class ConversationRemoteDataSourceImpl
    implements ConversationRemoteDataSource {
  final ApiClient _client;

  ConversationRemoteDataSourceImpl({required this._client});

  @override
  Future<List<ConversationDto>> getConversations() async {
    final response = await _client.get(ApiEndpoints.conversations);
    final list = response['conversations'] as List<dynamic>;
    return list
        .map((e) => ConversationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConversationDto> createConversation(
    List<String> participantIds, {
    Map<String, String>? encryptedKeys,
  }) async {
    final data = <String, dynamic>{
      'participant_ids': participantIds,
    };
    if (encryptedKeys != null) {
      data['encrypted_keys'] = encryptedKeys;
    }
    final response = await _client.post(
      ApiEndpoints.conversations,
      data: data,
    );
    return ConversationDto.fromJson(response);
  }

  @override
  Future<void> completeConversation(String conversationId) async {
    await _client.patch(
      ApiEndpoints.completeConversation(conversationId),
      data: {},
    );
  }

  @override
  Future<void> destroyConversation(String conversationId) async {
    await _client.delete(ApiEndpoints.conversationById(conversationId));
  }

  @override
  Future<List<MessageDto>> getMessages(String conversationId) async {
    final response =
        await _client.get(ApiEndpoints.messages(conversationId));
    final list = response['messages'] as List<dynamic>;
    return list
        .map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageDto> sendMessage(
      String conversationId, String ciphertext) async {
    final response = await _client.post(
      ApiEndpoints.messages(conversationId),
      data: SendMessageRequest(ciphertext: ciphertext).toJson(),
    );
    return MessageDto.fromJson(response);
  }

  @override
  Future<String> getGroupKey(String conversationId) async {
    final response =
        await _client.get(ApiEndpoints.conversationKeyById(conversationId));
    return response['encrypted_key'] as String;
  }

  @override
  Future<List<ParticipantDto>> getParticipants(
      String conversationId) async {
    final response =
        await _client.get(ApiEndpoints.conversationParticipants(conversationId));
    final list = response['participants'] as List<dynamic>;
    return list
        .map((e) => ParticipantDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UserDto>> searchUsers(String query) async {
    final response = await _client.get(
      ApiEndpoints.searchUsers,
      queryParameters: {'q': query},
    );
    final list = response['users'] as List<dynamic>;
    return list
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
