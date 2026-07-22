import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/connection_state.dart';
import '../../domain/entities/conversation_event.dart';
import '../../domain/repositories/message_repository.dart';
import 'message_repository_provider.dart';

/// Manages conversation state synchronization.
///
/// Responsibilities:
/// - Maintain conversation state across reconnections
/// - Process real-time events
/// - Handle reconnection: re-fetch state and flush pending messages
/// - Prepare for future offline sync
///
/// Architecture note:
/// This is a singleton-like service that lives for the app's lifetime.
/// It is provided via Riverpod and disposed when the app exits.
class ConversationSyncManager {
  final MessageRepository _repository;

  StreamSubscription<ConnectionState>? _connectionSub;
  ConnectionState _lastConnectionState = ConnectionState.disconnected;
  final Set<String> _activeConversations = {};

  /// Fired when conversation state needs refreshing.
  final StreamController<String> _refreshController =
      StreamController<String>.broadcast();

  /// Stream of conversation IDs that need refresh.
  Stream<String> get refreshStream => _refreshController.stream;

  ConversationSyncManager({
    required MessageRepository repository,
  })  : _repository = repository {
    _init();
  }

  void _init() {
    // Listen for connection state changes
    _connectionSub = _repository.observeConnectionState().listen((state) {
      final wasDisconnected =
          _lastConnectionState == ConnectionState.disconnected ||
              _lastConnectionState == ConnectionState.failed;
      final isNowConnected = state == ConnectionState.connected;

      if (wasDisconnected && isNowConnected) {
        _onReconnected();
      }

      _lastConnectionState = state;
    });
  }

  /// Register a conversation as active (being viewed or recently used).
  void registerConversation(String conversationId) {
    _activeConversations.add(conversationId);
  }

  /// Unregister a conversation (user left the screen).
  void unregisterConversation(String conversationId) {
    _activeConversations.remove(conversationId);
  }

  /// Called when the WebSocket reconnects after being disconnected.
  Future<void> _onReconnected() async {
    debugPrint('[SyncManager] Reconnected — refreshing ${_activeConversations.length} conversations');

    // Notify all active conversations to refresh
    for (final conversationId in _activeConversations) {
      _refreshController.add(conversationId);
    }

    // Flush pending messages for all conversations that had them
    await _flushAllPending();
  }

  /// Process a conversation event from WebSocket.
  Future<void> processEvent(ConversationEvent event) async {
    debugPrint('[SyncManager] Processing event: $event');

    switch (event.type) {
      case ConversationEventType.conversationCompleted:
      case ConversationEventType.conversationClosed:
      case ConversationEventType.conversationDestroyed:
        _refreshController.add(event.conversationId);
        break;
      case ConversationEventType.messageCreated:
      case ConversationEventType.messageUpdated:
      case ConversationEventType.messageFailed:
        // Handled by MessageRepositoryImpl directly
        break;
      case ConversationEventType.unknown:
        break;
    }
  }

  /// Flush all pending messages across all conversations.
  Future<void> _flushAllPending() async {
    // Pending message flushing is handled by ConversationDetailRepositoryImpl
    // and ConnectivityStateNotifier. This is a placeholder for future
    // sync-manager-level pending message handling.
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await _connectionSub?.cancel();
    await _refreshController.close();
    _activeConversations.clear();
  }
}

/// Riverpod provider for [ConversationSyncManager].
final conversationSyncManagerProvider = Provider<ConversationSyncManager>((ref) {
  final repository = ref.watch(messageRepositoryProvider);

  final manager = ConversationSyncManager(
    repository: repository,
  );

  ref.onDispose(() => manager.dispose());

  return manager;
});
