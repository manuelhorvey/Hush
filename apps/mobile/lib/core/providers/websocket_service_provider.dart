import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/websocket_service.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  throw UnimplementedError(
    'WebSocketService must be overridden in ProviderScope (see app/app.dart).',
  );
});
