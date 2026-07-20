import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/identity_service.dart';

final identityServiceProvider = Provider<IdentityService>((ref) {
  throw UnimplementedError(
    'IdentityService must be overridden in ProviderScope (see app/app.dart).',
  );
});
