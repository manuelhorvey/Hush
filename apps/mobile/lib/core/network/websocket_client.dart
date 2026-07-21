import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/environment.dart';

enum WsConnectionState { disconnected, connecting, connected }

enum WsEventType {
  messageReceived,
  conversationUpdated,
  conversationCompleted,
  conversationDestroyed,
  connectionChanged,
}

class WsEvent {
  final WsEventType type;
  final dynamic data;

  WsEvent({required this.type, this.data});
}

class WebSocketClient {
  final EnvironmentConfig _config;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 60;

  final _stateController = StreamController<WsConnectionState>.broadcast();
  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<WsConnectionState> get stateStream => _stateController.stream;
  Stream<WsEvent> get eventStream => _eventController.stream;

  WsConnectionState _connectionState = WsConnectionState.disconnected;

  WsConnectionState get connectionState => _connectionState;

  WebSocketClient({required this._config});

  Future<void> connect(String token) async {
    _token = token;
    if (_connectionState == WsConnectionState.connecting) return;
    _setState(WsConnectionState.connecting);
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed) return;
    try {
      final uri = Uri.parse(
        '${_config.wsBaseUrl}/ws?token=$_token',
      );
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[WS] Connection closed');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;
      if (type == null) return;

      WsEventType eventType;
      switch (type) {
        case 'message.received':
          eventType = WsEventType.messageReceived;
          break;
        case 'conversation.updated':
          eventType = WsEventType.conversationUpdated;
          break;
        case 'conversation.completed':
          eventType = WsEventType.conversationCompleted;
          break;
        case 'conversation.destroyed':
          eventType = WsEventType.conversationDestroyed;
          break;
        default:
          return;
      }

      _eventController.add(WsEvent(
        type: eventType,
        data: message['data'],
      ));
    } catch (e) {
      debugPrint('[WS] Failed to parse message: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _setState(WsConnectionState.disconnected);
    _channel = null;

    if (_token == null) return;

    _reconnectAttempts++;
    final delay = (_reconnectAttempts * 2).clamp(1, _maxReconnectDelay);
    debugPrint('[WS] Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_disposed) {
        _doConnect();
      }
    });
  }

  void _setState(WsConnectionState state) {
    _connectionState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _token = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    await _stateController.close();
    await _eventController.close();
  }
}
