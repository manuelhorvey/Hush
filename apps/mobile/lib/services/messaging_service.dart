// ignore_for_file: prefer_initializing_formals

import 'api_client.dart';

class ParticipantInfo {
  final String userId;
  final String username;

  ParticipantInfo({required this.userId, required this.username});

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['user_id'] as String,
      username: json['username'] as String,
    );
  }
}

class ConversationInfo {
  final String id;
  final List<ParticipantInfo> participants;
  final String status;
  final String? expiresAt;
  final String createdAt;

  ConversationInfo({
    required this.id,
    required this.participants,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    final list = (json['participants'] as List<dynamic>)
        .map((p) => ParticipantInfo.fromJson(p as Map<String, dynamic>))
        .toList();
    return ConversationInfo(
      id: json['id'] as String,
      participants: list,
      status: json['status'] as String? ?? 'active',
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}

class MessageInfo {
  final String id;
  final String senderId;
  final String ciphertext;
  final String createdAt;

  MessageInfo({
    required this.id,
    required this.senderId,
    required this.ciphertext,
    required this.createdAt,
  });

  factory MessageInfo.fromJson(Map<String, dynamic> json) {
    return MessageInfo(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      ciphertext: json['ciphertext'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class UserInfo {
  final String id;
  final String username;

  UserInfo({required this.id, required this.username});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      username: json['username'] as String,
    );
  }
}

class MessagingService {
  final ApiClient _api;

  MessagingService({required ApiClient api}) : _api = api;

  Future<List<ConversationInfo>> listConversations(String token) async {
    final data = await _api.get('/api/v1/conversations', token: token);
    final list = data['conversations'] as List<dynamic>;
    return list
        .map((c) => ConversationInfo.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationInfo> createConversation(
    String token,
    List<String> participantIds, {
    Map<String, String>? encryptedKeys,
  }) async {
    final body = <String, dynamic>{
      'participant_ids': participantIds,
    };
    if (encryptedKeys != null) {
      body['encrypted_keys'] = encryptedKeys;
    }
    final data = await _api.post(
      '/api/v1/conversations',
      body,
      token: token,
    );
    return ConversationInfo.fromJson(data);
  }

  Future<List<MessageInfo>> listMessages(
      String token, String conversationId) async {
    final data = await _api.get(
      '/api/v1/conversations/$conversationId/messages',
      token: token,
    );
    final list = data['messages'] as List<dynamic>;
    return list
        .map((m) => MessageInfo.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MessageInfo> sendMessage(
      String token, String conversationId, String ciphertext) async {
    final data = await _api.post(
      '/api/v1/conversations/$conversationId/messages',
      {'ciphertext': ciphertext},
      token: token,
    );
    return MessageInfo.fromJson(data);
  }

  Future<List<UserInfo>> searchUsers(String token, String query) async {
    final data = await _api.get(
      '/api/v1/users/search?q=${Uri.encodeQueryComponent(query)}',
      token: token,
    );
    final list = data['users'] as List<dynamic>;
    return list
        .map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationInfo> completeConversation(
      String token, String conversationId) async {
    final data = await _api.patch(
      '/api/v1/conversations/$conversationId/complete',
      {},
      token: token,
    );
    return ConversationInfo.fromJson(data);
  }

  Future<void> destroyConversation(
      String token, String conversationId) async {
    await _api.delete(
      '/api/v1/conversations/$conversationId',
      token: token,
    );
  }

  Future<String> getGroupKey(String token, String conversationId) async {
    final data = await _api.get(
      '/api/v1/conversations/$conversationId/key',
      token: token,
    );
    return data['encrypted_key'] as String;
  }

  Future<List<ParticipantInfo>> getParticipants(
      String token, String conversationId) async {
    final data = await _api.get(
      '/api/v1/conversations/$conversationId/participants',
      token: token,
    );
    final list = data['participants'] as List<dynamic>;
    return list
        .map((p) => ParticipantInfo.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
