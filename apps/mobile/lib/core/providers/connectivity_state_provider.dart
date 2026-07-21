import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/conversations/conversation/presentation/providers/conversation_detail_repository_provider.dart';
import '../../services/connectivity_monitor.dart';
import '../../services/local_cache_service.dart';

class ConnectivityState {
  final bool isOnline;

  const ConnectivityState({this.isOnline = true});
}

class ConnectivityStateNotifier extends Notifier<ConnectivityState> {
  @override
  ConnectivityState build() {
    final monitor = ref.read(connectivityMonitorProvider);
    monitor.start((online) {
      state = ConnectivityState(isOnline: online);
      if (online) {
        _flushPendingMessages();
      }
    });
    ref.onDispose(() => monitor.stop());
    return const ConnectivityState();
  }

  void setOnline(bool v) {
    if (state.isOnline != v) {
      state = ConnectivityState(isOnline: v);
    }
  }

  Future<void> _flushPendingMessages() async {
    try {
      final cache = ref.read(localCacheServiceProvider);
      final ids = await cache.getPendingConversationIds();
      for (final conversationId in ids) {
        try {
          final repo = ref.read(conversationDetailRepositoryProvider);
          await repo.flushPendingMessages(conversationId);
        } catch (_) {
          // Best-effort per conversation
        }
      }
    } catch (_) {
      // Best-effort
    }
  }
}

final connectivityStateProvider =
    NotifierProvider<ConnectivityStateNotifier, ConnectivityState>(
  ConnectivityStateNotifier.new,
);
