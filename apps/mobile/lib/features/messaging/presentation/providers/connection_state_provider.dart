import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/websocket_client.dart';
import '../../../../core/providers/network_providers.dart';
import '../../domain/entities/connection_state.dart';

/// State for the WebSocket connection.
class ConnectionStateInfo {
  final ConnectionState state;
  final DateTime? lastConnected;
  final int reconnectAttempts;

  const ConnectionStateInfo({
    this.state = ConnectionState.disconnected,
    this.lastConnected,
    this.reconnectAttempts = 0,
  });

  ConnectionStateInfo copyWith({
    ConnectionState? state,
    DateTime? lastConnected,
    int? reconnectAttempts,
  }) {
    return ConnectionStateInfo(
      state: state ?? this.state,
      lastConnected: lastConnected ?? this.lastConnected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }

  String get label => state.label;

  bool get isOnline => state.isOnline;
}

/// Notifier for WebSocket connection state.
///
/// Wraps the [WebSocketClient]'s state stream and provides a
/// clean Riverpod interface for tracking connection status.
class ConnectionStateNotifier extends Notifier<ConnectionStateInfo> {
  StreamSubscription<WsConnectionState>? _sub;

  @override
  ConnectionStateInfo build() {
    try {
      final wsClient = ref.watch(webSocketClientProvider);
      _sub = wsClient.stateStream.listen((wsState) {
        final mapped = switch (wsState) {
          WsConnectionState.disconnected => ConnectionState.disconnected,
          WsConnectionState.connecting => ConnectionState.connecting,
          WsConnectionState.connected => ConnectionState.connected,
        };

        state = state.copyWith(
          state: mapped,
          lastConnected: mapped == ConnectionState.connected
              ? DateTime.now()
              : state.lastConnected,
          reconnectAttempts: mapped == ConnectionState.connected
              ? 0
              : state.reconnectAttempts + 1,
        );
      });
    } catch (_) {
      // WS client not available
    }

    ref.onDispose(() => _sub?.cancel());

    return const ConnectionStateInfo();
  }
}

/// Provider for connection state.
final connectionStateProvider =
    NotifierProvider<ConnectionStateNotifier, ConnectionStateInfo>(
  ConnectionStateNotifier.new,
);
