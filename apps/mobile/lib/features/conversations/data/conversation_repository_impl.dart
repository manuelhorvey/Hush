import '../../../services/local_cache_service.dart';
import '../../../services/messaging_service.dart';
import '../domain/conversation_repository.dart';
import '../models/conversation.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final MessagingService _messaging;
  final CacheService _cache;
  final String? Function() _tokenProvider;

  ConversationRepositoryImpl({
    required this._messaging,
    required this._cache,
    required this._tokenProvider,
  });

  String get _token {
    final t = _tokenProvider();
    if (t == null) throw Exception('Not authenticated');
    return t;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    final token = _token;
    try {
      final infos = await _messaging.listConversations(token);
      final conversations = infos.map(_mapConversationInfo).toList();
      await _cache.cacheConversations(conversations);
      return conversations;
    } catch (_) {
      final cached = await _cache.getCachedConversations();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  }) async {
    final token = _token;
    final info = await _messaging.createConversation(
      token,
      participantIds,
      encryptedKeys: encryptedKeys,
    );
    final conversation = _mapConversationInfo(info);
    await _updateCacheAfterMutation();
    return conversation;
  }

  @override
  Future<Conversation> completeConversation(String id) async {
    final token = _token;
    final info = await _messaging.completeConversation(token, id);
    await _updateCacheAfterMutation();
    return _mapConversationInfo(info);
  }

  @override
  Future<void> destroyConversation(String id) async {
    final token = _token;
    await _messaging.destroyConversation(token, id);
    await _updateCacheAfterMutation();
  }

  Future<void> _updateCacheAfterMutation() async {
    try {
      final token = _token;
      final infos = await _messaging.listConversations(token);
      await _cache.cacheConversations(
        infos.map(_mapConversationInfo).toList(),
      );
    } catch (_) {
      // Best-effort cache refresh
    }
  }

  @override
  Future<List<({String id, String username})>> searchUsers(String query) async {
    final token = _token;
    final users = await _messaging.searchUsers(token, query);
    return users.map((u) => (id: u.id, username: u.username)).toList();
  }

  Conversation _mapConversationInfo(ConversationInfo info) {
    return Conversation(
      id: info.id,
      participants: info.participants
          .map((p) => ConversationParticipant(
                id: p.userId,
                displayName: p.username,
              ))
          .toList(),
      lifecycle: _mapStatus(info.status),
      createdAt: DateTime.tryParse(info.createdAt) ?? DateTime.now(),
      completedAt:
          info.expiresAt != null ? DateTime.tryParse(info.expiresAt!) : null,
      isVerified: false,
    );
  }

  ConversationLifecycle _mapStatus(String status) {
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
