import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_state_provider.dart';
import '../../../../core/providers/crypto_service_provider.dart';
import '../../../../core/providers/websocket_service_provider.dart';
import '../../../../features/identity/presentation/providers/identity_service_provider.dart';
import '../../../../services/websocket_service.dart';
import '../../models/conversation.dart';
import 'conversation_repository_provider.dart';

enum ConversationsStatus { loading, loaded, empty, error }

class ConversationsState {
  final List<Conversation> conversations;
  final ConversationsStatus status;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.status = ConversationsStatus.loading,
    this.error,
  });

  List<Conversation> get activeConversations =>
      conversations.where((c) => c.lifecycle.isOpen).toList();

  List<Conversation> get closedConversations =>
      conversations.where((c) => !c.lifecycle.isOpen).toList();
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  ConversationsState build() {
    _wsSub?.cancel();
    try {
      final ws = ref.read(webSocketServiceProvider);
      _wsSub = ws.eventStream.listen((event) {
        if (event.type == WsEventType.conversationUpdated) {
          load();
        }
      });
    } catch (_) {
      // WS provider not yet available
    }
    ref.onDispose(() => _wsSub?.cancel());
    return const ConversationsState();
  }

  Future<void> load() async {
    state = const ConversationsState(status: ConversationsStatus.loading);

    try {
      final repo = ref.read(conversationRepositoryProvider);
      final conversations = await repo.listConversations();

      state = ConversationsState(
        conversations: conversations,
        status: conversations.isEmpty
            ? ConversationsStatus.empty
            : ConversationsStatus.loaded,
      );
    } catch (e) {
      state = ConversationsState(
        status: ConversationsStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<Conversation> createConversation({
    required List<String> participantIds,
    Map<String, String>? encryptedKeys,
  }) async {
    if (encryptedKeys == null && participantIds.length > 1) {
      final crypto = ref.read(cryptoServiceProvider);
      final identity = ref.read(identityServiceProvider);
      final auth = ref.read(authStateProvider);
      final token = auth.token;
      final currentUserId = auth.userId;
      if (token != null && currentUserId != null) {
        final groupKey = crypto.generateGroupKey();
        encryptedKeys = {};
        final allIds = [currentUserId, ...participantIds];
        for (final pid in allIds) {
          try {
            final pubKey = await identity.getExchangeKey(token, pid);
            if (pubKey.isNotEmpty) {
              encryptedKeys[pid] = await crypto.encryptGroupKey(groupKey, pubKey);
            }
          } catch (_) {
            // Skip participants whose exchange keys we can't fetch
          }
        }
      }
    }
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = await repo.createConversation(
      participantIds: participantIds,
      encryptedKeys: encryptedKeys,
    );
    await load();
    return conversation;
  }

  Future<Conversation> completeConversation(String id) async {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = await repo.completeConversation(id);
    final list = state.conversations.map((c) => c.id == id ? conversation : c).toList();
    state = ConversationsState(
      conversations: list,
      status: ConversationsStatus.loaded,
    );
    return conversation;
  }

  Future<void> destroyConversation(String id) async {
    final repo = ref.read(conversationRepositoryProvider);
    await repo.destroyConversation(id);
    state = ConversationsState(
      conversations: state.conversations.where((c) => c.id != id).toList(),
      status: state.conversations.length > 1
          ? ConversationsStatus.loaded
          : ConversationsStatus.empty,
    );
  }

  Future<List<({String id, String username})>> searchUsers(String query) async {
    final repo = ref.read(conversationRepositoryProvider);
    return repo.searchUsers(query);
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
);
