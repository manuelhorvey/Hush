import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_state_provider.dart';
import '../../../../core/providers/conversations_state_provider.dart';
import '../../../../services/local_cache_service.dart';
import '../../data/conversation_repository_impl.dart';
import '../../domain/conversation_repository.dart';

final conversationRepositoryProvider =
    Provider<ConversationRepository>((ref) {
  final messaging = ref.watch(messagingServiceProvider);
  final auth = ref.watch(authStateProvider);

  return ConversationRepositoryImpl(
    messaging: messaging,
    cache: ref.watch(localCacheServiceProvider),
    tokenProvider: () => auth.token,
    userIdProvider: () => auth.userId,
  );
});
