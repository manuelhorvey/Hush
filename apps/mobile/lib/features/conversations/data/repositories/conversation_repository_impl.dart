import '../../../../core/network/network_errors.dart';
import '../../domain/conversation_repository.dart';
import '../../models/conversation.dart';
import '../datasources/conversation_remote_datasource.dart';
import '../models/conversation_dto.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource _remoteDataSource;

  ConversationRepositoryImpl({
    required this._remoteDataSource,
  });

  @override
  Future<List<Conversation>> listConversations() async {
    try {
      final dtos = await _remoteDataSource.getConversations();
      return dtos.map(_mapToDomain).toList();
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  }) async {
    try {
      final dto = await _remoteDataSource.createConversation(
        participantIds,
        encryptedKeys: encryptedKeys,
      );
      return _mapToDomain(dto);
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<Conversation> completeConversation(String id) async {
    try {
      await _remoteDataSource.completeConversation(id);
      return Conversation(
        id: id,
        participants: [],
        lifecycle: ConversationLifecycle.closed,
        createdAt: DateTime.now(),
      );
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<void> destroyConversation(String id) async {
    try {
      await _remoteDataSource.destroyConversation(id);
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<List<({String id, String username})>> searchUsers(
      String query) async {
    try {
      final users = await _remoteDataSource.searchUsers(query);
      return users
          .map((u) => (id: u.id, username: u.username))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  Conversation _mapToDomain(ConversationDto dto) {
    final lifecycle = _mapLifecycle(dto.status);
    return Conversation(
      id: dto.id,
      participants: dto.participants
          .map((p) => ConversationParticipant(
                id: p.userId,
                displayName: p.username,
              ))
          .toList(),
      lifecycle: lifecycle,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      completedAt: dto.expiresAt != null
          ? DateTime.tryParse(dto.expiresAt!)
          : null,
      isVerified: dto.isVerified ?? false,
    );
  }

  ConversationLifecycle _mapLifecycle(String status) {
    switch (status) {
      case 'active':
        return ConversationLifecycle.active;
      case 'completed':
        return ConversationLifecycle.closed;
      case 'destroyed':
        return ConversationLifecycle.closed;
      default:
        return ConversationLifecycle.active;
    }
  }
}
