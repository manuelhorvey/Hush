import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/connection_state.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';
import 'message_repository_provider.dart';

/// Screen status for the message list.
enum MessageScreenStatus { loading, loaded, error }

/// State for a conversation's message list.
class MessageListState {
  final List<Message> messages;
  final MessageScreenStatus status;
  final String? error;
  final String connectionLabel;

  /// Whether the conversation is still accepting messages.
  final bool isActive;

  /// Lifecycle status string: 'active', 'completed', 'destroyed'.
  final String lifecycleStatus;

  /// When the conversation was completed, if applicable.
  final DateTime? completedAt;

  const MessageListState({
    this.messages = const [],
    this.status = MessageScreenStatus.loading,
    this.error,
    this.connectionLabel = 'Connected',
    this.isActive = true,
    this.lifecycleStatus = 'active',
    this.completedAt,
  });

  MessageListState copyWith({
    List<Message>? messages,
    MessageScreenStatus? status,
    String? error,
    String? connectionLabel,
    bool? isActive,
    String? lifecycleStatus,
    DateTime? completedAt,
  }) {
    return MessageListState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: error ?? this.error,
      connectionLabel: connectionLabel ?? this.connectionLabel,
      isActive: isActive ?? this.isActive,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Notifier managing the message list for a single conversation.
///
/// Responsibilities:
/// - Load messages from repository
/// - Listen for real-time message updates via WebSocket
/// - Support optimistic UI for sending messages
/// - Support pagination (loading older messages)
class MessageListNotifier extends Notifier<MessageListState> {
  String? _conversationId;
  StreamSubscription<Message>? _messageSub;
  StreamSubscription<ConnectionState>? _connectionSub;

  @override
  MessageListState build() {
    ref.onDispose(() {
      _messageSub?.cancel();
      _connectionSub?.cancel();
    });
    return const MessageListState();
  }

  /// Load messages for a conversation and start listening for real-time updates.
  Future<void> load(String conversationId) async {
    _conversationId = conversationId;
    state = state.copyWith(status: MessageScreenStatus.loading);

    try {
      final repo = ref.read(messageRepositoryProvider);
      final messages = await repo.getMessages(conversationId);

      state = state.copyWith(
        messages: messages,
        status: MessageScreenStatus.loaded,
      );

      // Start listening for real-time messages
      _messageSub?.cancel();
      _messageSub = repo.observeMessages(conversationId).listen((message) {
        _onMessageReceived(message);
      });

      // Start listening for connection state changes
      _connectionSub?.cancel();
      _connectionSub = repo.observeConnectionState().listen((connState) {
        state = state.copyWith(
          connectionLabel: connState.label,
        );
      });
    } catch (e) {
      state = state.copyWith(
        status: MessageScreenStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Send a message with optimistic UI update.
  Future<bool> sendMessage(String plaintext) async {
    final conversationId = _conversationId;
    if (conversationId == null) return false;

    final repo = ref.read(messageRepositoryProvider);

    // Optimistic update: add a sending message immediately
    final optimistic = Message(
      id: '', // Temporary — server will assign real ID
      conversationId: conversationId,
      senderId: '',
      senderName: 'You',
      content: plaintext,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimistic],
    );

    // Actual send
    try {
      final result = await repo.sendMessage(
        conversationId: conversationId,
        plaintext: plaintext,
        currentUserId: '',
        currentUserName: 'You',
      );

      // Replace optimistic message with real one
      final updated = state.messages.map((m) {
        if (m == optimistic) return result;
        return m;
      }).toList();

      state = state.copyWith(messages: updated);
      return true;
    } catch (e) {
      // Mark as failed
      final updated = state.messages.map((m) {
        if (m == optimistic) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updated);
      return false;
    }
  }

  /// Retry sending a failed message.
  Future<void> retryMessage(Message failedMessage) async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    final repo = ref.read(messageRepositoryProvider);

    // Mark as sending
    final updated = state.messages.map((m) {
      if (m.id == failedMessage.id && m.status == MessageStatus.failed) {
        return m.copyWith(status: MessageStatus.sending);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);

    try {
      final result = await repo.retryMessage(conversationId, failedMessage);
      final finalList = state.messages.map((m) {
        if (m.status == MessageStatus.sending &&
            m.content == failedMessage.content) {
          return result;
        }
        return m;
      }).toList();
      state = state.copyWith(messages: finalList);
    } catch (e) {
      // Restore failed state
      final restored = state.messages.map((m) {
        if (m.status == MessageStatus.sending) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: restored);
    }
  }

  /// Update lifecycle status from outside (e.g., after API call succeeds).
  void markLifecycle({
    required bool isActive,
    required String lifecycleStatus,
    DateTime? completedAt,
  }) {
    state = state.copyWith(
      isActive: isActive,
      lifecycleStatus: lifecycleStatus,
      completedAt: completedAt,
    );
  }

  /// Load more (older) messages.
  Future<void> loadMore() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    try {
      final repo = ref.read(messageRepositoryProvider);
      final older = await repo.getMessages(
        conversationId,
        limit: 50,
        before: state.messages.firstOrNull?.id,
      );
      state = state.copyWith(
        messages: [...older, ...state.messages],
      );
    } catch (_) {
      // Silently fail for pagination
    }
  }



  void _onMessageReceived(Message message) {
    // Avoid duplicates
    final exists = state.messages.any((m) => m.id == message.id);
    if (exists) return;

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }
}

/// Provider for the message list state.
final messageListProvider =
    NotifierProvider<MessageListNotifier, MessageListState>(
  MessageListNotifier.new,
);
