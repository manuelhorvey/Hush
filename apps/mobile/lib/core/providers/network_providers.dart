import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';
import '../storage/secure_storage.dart';

final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  return EnvironmentConfig.current;
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(environmentConfigProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(config: config, storage: storage);
});

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return WebSocketClient(config: config);
});
