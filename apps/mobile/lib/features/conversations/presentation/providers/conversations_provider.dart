import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conversation_repository_impl.dart';
import '../../domain/conversation_repository.dart';
import '../../models/conversation.dart';

final conversationRepositoryProvider =
    Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl();
});

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
  @override
  ConversationsState build() => const ConversationsState();

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
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
);


