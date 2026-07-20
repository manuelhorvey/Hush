import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/messaging_service.dart';

class ConversationsState {
  final List<ConversationInfo> conversations;
  final bool loading;

  const ConversationsState({
    this.conversations = const [],
    this.loading = false,
  });
}

class ConversationsStateNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() => const ConversationsState();

  Future<void> load() async {
    final token = ref.read(authStateProvider).token;
    if (token == null) return;

    state = ConversationsState(loading: true);

    try {
      final messaging = ref.read(messagingServiceProvider);
      final conversations = await messaging.listConversations(token);
      state = ConversationsState(conversations: conversations, loading: false);
    } catch (_) {
      state = const ConversationsState(loading: false);
    }
  }

  Future<ConversationInfo> create(
    List<String> participantIds, {
    Map<String, String>? encryptedKeys,
  }) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) throw Exception('Not authenticated');

    final messaging = ref.read(messagingServiceProvider);
    final conv = await messaging.createConversation(
      token,
      participantIds,
      encryptedKeys: encryptedKeys,
    );
    state = ConversationsState(
      conversations: [conv, ...state.conversations],
      loading: false,
    );
    return conv;
  }

  Future<ConversationInfo> complete(String id) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) throw Exception('Not authenticated');

    final messaging = ref.read(messagingServiceProvider);
    final conv = await messaging.completeConversation(token, id);
    final list = state.conversations.map((c) => c.id == id ? conv : c).toList();
    state = ConversationsState(conversations: list, loading: false);
    return conv;
  }

  Future<void> destroy(String id) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) throw Exception('Not authenticated');

    final messaging = ref.read(messagingServiceProvider);
    await messaging.destroyConversation(token, id);
    state = ConversationsState(
      conversations: state.conversations.where((c) => c.id != id).toList(),
      loading: false,
    );
  }
}

final conversationsStateProvider =
    NotifierProvider<ConversationsStateNotifier, ConversationsState>(
  ConversationsStateNotifier.new,
);

final messagingServiceProvider = Provider<MessagingService>((ref) {
  throw UnimplementedError('MessagingService must be overridden in ProviderScope');
});
