/// Represents the state of the WebSocket connection.
enum ConnectionState {
  /// Not connected — initial state or after explicit disconnect
  disconnected,

  /// Attempting to connect
  connecting,

  /// Connected and receiving events
  connected,

  /// Connection lost, attempting to reconnect
  reconnecting,

  /// Connection failed after exhausting retries
  failed;

  String get label {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.reconnecting:
        return 'Reconnecting';
      case ConnectionState.failed:
        return 'Connection failed';
    }
  }

  bool get isOnline => this == ConnectionState.connected;
  bool get isTransitioning =>
      this == ConnectionState.connecting || this == ConnectionState.reconnecting;
}
