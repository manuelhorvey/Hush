import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/crypto_service.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  throw UnimplementedError(
    'CryptoService must be overridden in ProviderScope (see app/app.dart).',
  );
});
