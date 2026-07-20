import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/identity_repository_impl.dart';
import '../../domain/identity_repository.dart';
import 'identity_service_provider.dart';

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  final service = ref.watch(identityServiceProvider);
  return IdentityRepositoryImpl(service: service);
});
