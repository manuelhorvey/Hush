import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

String get wsHost {
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}

enum WsConnectionState { disconnected, connecting, connected, failed }

enum WsEventType { messageReceived, conversationUpdated, connectionChanged }

class WsEvent {
  final WsEventType type;
  final dynamic data;

  const WsEvent({required this.type, this.data});
}

class WebSocketService {
  WebSocket? _ws;
  Timer? _reconnectTimer;
  String? _token;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  final int _basePort = 8080;
  final int _maxReconnectDelay = 60;

  final _stateController =
      StreamController<WsConnectionState>.broadcast();
  final _eventController = StreamController<WsEvent>.broadcast();

  WsConnectionState _state = WsConnectionState.disconnected;

  WsConnectionState get state => _state;
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  Stream<WsEvent> get eventStream => _eventController.stream;

  void _setState(WsConnectionState newState) {
    _state = newState;
    if (!_disposed) {
      _stateController.add(newState);
    }
  }

  Future<void> connect(String token) async {
    _token = token;
    _reconnectAttempt = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed) return;
    if (_token == null) return;

    _setState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('ws://$wsHost:$_basePort/ws?token=$_token');
      _ws = await WebSocket.connect(uri.toString());

      _setState(WsConnectionState.connected);
      _reconnectAttempt = 0;

      _ws!.listen(
        (data) {
          if (_disposed) return;
          try {
            final decoded = jsonDecode(data as String);
            final type = switch (decoded['type'] as String? ?? '') {
              'message' => WsEventType.messageReceived,
              'conversation_updated' => WsEventType.conversationUpdated,
              _ => WsEventType.messageReceived,
            };
            _eventController.add(WsEvent(
              type: type,
              data: decoded['data'] ?? decoded,
            ));
          } catch (_) {
            // Ignore unparseable messages
          }
        },
        onDone: () {
          if (!_disposed) {
            _setState(WsConnectionState.disconnected);
            _scheduleReconnect();
          }
        },
        onError: (error) {
          if (!_disposed) {
            _setState(WsConnectionState.failed);
            _scheduleReconnect();
          }
        },
      );
    } catch (_) {
      if (!_disposed) {
        _setState(WsConnectionState.failed);
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    final delay = _reconnectDelay();
    _reconnectTimer = Timer(Duration(seconds: delay), _doConnect);
  }

  int _reconnectDelay() {
    final delay = 1 << _reconnectAttempt.clamp(0, 5);
    _reconnectAttempt++;
    return delay.clamp(1, _maxReconnectDelay);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _ws?.close();
    _ws = null;
    _setState(WsConnectionState.disconnected);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _ws?.close();
    _ws = null;
    await _stateController.close();
    await _eventController.close();
  }
}
