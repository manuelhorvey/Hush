import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/network_providers.dart';
import '../data/datasources/identity_remote_datasource.dart';
import '../data/repositories/identity_repository_impl.dart';
import '../domain/identity_repository.dart';

final identityRemoteDataSourceProvider =
    Provider<IdentityRemoteDataSource>((ref) {
  return IdentityRemoteDataSourceImpl(client: ref.watch(apiClientProvider));
});

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  return IdentityRepositoryImpl(
    remoteDataSource: ref.watch(identityRemoteDataSourceProvider),
  );
});
