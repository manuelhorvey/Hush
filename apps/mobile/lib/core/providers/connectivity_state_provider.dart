import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/connectivity_monitor.dart';

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
    // This hook lets the app flush queued messages when connectivity returns.
    // The actual flush is driven by the notifier's consumer.
  }
}

final connectivityStateProvider =
    NotifierProvider<ConnectivityStateNotifier, ConnectivityState>(
  ConnectivityStateNotifier.new,
);
