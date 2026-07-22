import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_state_provider.dart';
import '../../../../core/providers/conversations_state_provider.dart';
import '../../../../core/providers/crypto_service_provider.dart';
import '../../../../core/providers/websocket_service_provider.dart';
import '../../../../features/identity/presentation/providers/identity_service_provider.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/repositories/message_repository.dart';

/// Provider for [MessageRepository].
///
/// Wires together all dependencies from the existing infrastructure.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final messaging = ref.watch(messagingServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  final crypto = ref.watch(cryptoServiceProvider);
  final identity = ref.watch(identityServiceProvider);
  final auth = ref.watch(authStateProvider);

  final remoteDataSource = MessageRemoteDataSource(messaging: messaging);

  return MessageRepositoryImpl(
    remoteDataSource: remoteDataSource,
    wsService: ws,
    crypto: crypto,
    identity: identity,
    messaging: messaging,
    tokenProvider: () => auth.token,
    userIdProvider: () => auth.userId,
  );
});
