import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conversation_detail_repository_impl.dart';
import '../../domain/conversation_detail_repository.dart';
import '../../models/message.dart';

final conversationDetailRepositoryProvider =
    Provider<ConversationDetailRepository>((ref) {
  return ConversationDetailRepositoryImpl();
});

enum ConversationScreenStatus { loading, loaded, error }

class ConversationDetailState {
  final ConversationScreenStatus screenStatus;
  final List<Message> messages;
  final bool isActive;
  final String lifecycleStatus;
  final DateTime? completedAt;
  final String? error;

  const ConversationDetailState({
    this.screenStatus = ConversationScreenStatus.loading,
    this.messages = const [],
    this.isActive = true,
    this.lifecycleStatus = 'active',
    this.completedAt,
    this.error,
  });

  ConversationDetailState copyWith({
    ConversationScreenStatus? screenStatus,
    List<Message>? messages,
    bool? isActive,
    String? lifecycleStatus,
    DateTime? completedAt,
    String? error,
  }) {
    return ConversationDetailState(
      screenStatus: screenStatus ?? this.screenStatus,
      messages: messages ?? this.messages,
      isActive: isActive ?? this.isActive,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }
}

class ConversationDetailNotifier
    extends Notifier<ConversationDetailState> {
  @override
  ConversationDetailState build() => const ConversationDetailState();

  Future<void> load(String conversationId) async {
    state = state.copyWith(screenStatus: ConversationScreenStatus.loading);
    try {
      final repo = ref.read(conversationDetailRepositoryProvider);
      final messages = await repo.getMessages(conversationId);
      final status = repo.getStatus(conversationId);
      state = ConversationDetailState(
        messages: messages,
        isActive: status == 'active',
        lifecycleStatus: status,
        screenStatus: ConversationScreenStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        screenStatus: ConversationScreenStatus.error,
        error: 'Unable to load conversation.',
      );
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    final repo = ref.read(conversationDetailRepositoryProvider);
    await repo.sendMessage(conversationId, content.trim());
    await load(conversationId);
  }

  Future<void> completeConversation(String conversationId) async {
    final repo = ref.read(conversationDetailRepositoryProvider);
    await repo.completeConversation(conversationId);      state = state.copyWith(
        isActive: false,
        lifecycleStatus: 'completed',
        completedAt: DateTime.now(),
      );
  }

  Future<void> destroyConversation(String conversationId) async {
    final repo = ref.read(conversationDetailRepositoryProvider);
    await repo.destroyConversation(conversationId);
    state = state.copyWith(
      isActive: false,
      lifecycleStatus: 'destroyed',
    );
  }
}

final conversationDetailProvider = NotifierProvider<
    ConversationDetailNotifier, ConversationDetailState>(
  ConversationDetailNotifier.new,
);
