import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/message.dart';
import 'conversation_detail_repository_provider.dart';

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
  StreamSubscription<Message>? _messageSub;

  @override
  ConversationDetailState build() {
    ref.onDispose(() {
      _messageSub?.cancel();
    });
    return const ConversationDetailState();
  }

  Future<void> load(String conversationId) async {
    state = state.copyWith(screenStatus: ConversationScreenStatus.loading);
    try {
      final repo = ref.read(conversationDetailRepositoryProvider);
      final messages = await repo.getMessages(conversationId);
      final status = await repo.getStatus(conversationId);

      state = ConversationDetailState(
        messages: messages,
        isActive: status.name == 'active',
        lifecycleStatus: status.name,
        screenStatus: ConversationScreenStatus.loaded,
      );

      _listenForMessages(conversationId);
    } catch (e) {
      state = state.copyWith(
        screenStatus: ConversationScreenStatus.error,
        error: e.toString(),
      );
    }
  }

  void _listenForMessages(String conversationId) {
    _messageSub?.cancel();
    final repo = ref.read(conversationDetailRepositoryProvider);

    _messageSub = repo.messageStream(conversationId).listen((message) {
      final current = state;
      if (!current.messages.any((m) => m.id == message.id)) {
        state = current.copyWith(
          messages: [...current.messages, message],
        );
      }
    });
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return false;
    final repo = ref.read(conversationDetailRepositoryProvider);
    final success = await repo.sendMessage(conversationId, content.trim());
    if (!success) {
      state = state.copyWith(
        error: 'Message queued — will send when back online.',
      );
    }
    return success;
  }

  Future<bool> completeConversation(String conversationId) async {
    final repo = ref.read(conversationDetailRepositoryProvider);
    final success = await repo.completeConversation(conversationId);
    if (success) {
      state = state.copyWith(
        isActive: false,
        lifecycleStatus: 'completed',
        completedAt: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        error: 'Failed to complete moment.',
      );
    }
    return success;
  }

  Future<bool> destroyConversation(String conversationId) async {
    final repo = ref.read(conversationDetailRepositoryProvider);
    final success = await repo.destroyConversation(conversationId);
    if (success) {
      _messageSub?.cancel();
      state = state.copyWith(
        isActive: false,
        lifecycleStatus: 'destroyed',
      );
    } else {
      state = state.copyWith(
        error: 'Failed to destroy moment.',
      );
    }
    return success;
  }
}

final conversationDetailProvider = NotifierProvider<
    ConversationDetailNotifier, ConversationDetailState>(
  ConversationDetailNotifier.new,
);
