import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/auth_state_provider.dart';
import '../../../../../core/providers/conversations_state_provider.dart';
import '../../../../../core/providers/crypto_service_provider.dart';
import '../../../../../core/providers/websocket_service_provider.dart';
import '../../../../../features/identity/presentation/providers/identity_service_provider.dart';
import '../../../../../services/local_cache_service.dart';
import '../../data/conversation_detail_repository_impl.dart';
import '../../domain/conversation_detail_repository.dart';

final conversationDetailRepositoryProvider =
    Provider<ConversationDetailRepository>((ref) {
  final messaging = ref.watch(messagingServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  final crypto = ref.watch(cryptoServiceProvider);
  final identity = ref.watch(identityServiceProvider);
  final auth = ref.watch(authStateProvider);

  return ConversationDetailRepositoryImpl(
    messaging: messaging,
    ws: ws,
    crypto: crypto,
    identity: identity,
    cache: ref.watch(localCacheServiceProvider),
    tokenProvider: () => auth.token,
    userIdProvider: () => auth.userId,
  );
});
