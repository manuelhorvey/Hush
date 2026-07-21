import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/config/environment.dart';

void main() {
  group('EnvironmentConfig', () {
    test('development has correct values', () {
      final config = EnvironmentConfig.development;
      expect(config.environment, AppEnvironment.development);
      expect(config.apiBaseUrl, 'http://10.0.2.2:8080');
      expect(config.wsBaseUrl, 'ws://10.0.2.2:8080');
      expect(config.enableLogging, isTrue);
    });

    test('staging has correct values', () {
      final config = EnvironmentConfig.staging;
      expect(config.environment, AppEnvironment.staging);
      expect(config.apiBaseUrl, 'https://staging.api.hush.app');
      expect(config.wsBaseUrl, 'wss://staging.api.hush.app');
      expect(config.enableLogging, isTrue);
    });

    test('production has correct values', () {
      final config = EnvironmentConfig.production;
      expect(config.environment, AppEnvironment.production);
      expect(config.apiBaseUrl, 'https://api.hush.app');
      expect(config.wsBaseUrl, 'wss://api.hush.app');
      expect(config.enableLogging, isFalse);
    });

    test('label returns correct string', () {
      expect(EnvironmentConfig.development.label, 'dev');
      expect(EnvironmentConfig.staging.label, 'staging');
      expect(EnvironmentConfig.production.label, 'production');
    });

    test('default timeouts are set', () {
      const config = EnvironmentConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://test',
        wsBaseUrl: 'ws://test',
      );
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 30));
    });
  });
}
