import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/network_providers.dart';
import '../data/datasources/conversation_remote_datasource.dart';
import '../data/repositories/conversation_repository_impl.dart';
import '../domain/conversation_repository.dart';

final conversationRemoteDataSourceProvider =
    Provider<ConversationRemoteDataSource>((ref) {
  return ConversationRemoteDataSourceImpl(client: ref.watch(apiClientProvider));
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(
    remoteDataSource: ref.watch(conversationRemoteDataSourceProvider),
  );
});
