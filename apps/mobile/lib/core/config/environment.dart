import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class EnvironmentConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool enableLogging;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    this.enableLogging = false,
    this.connectTimeout = defaultConnectTimeout,
    this.receiveTimeout = defaultReceiveTimeout,
  });

  static const defaultConnectTimeout = Duration(seconds: 10);
  static const defaultReceiveTimeout = Duration(seconds: 30);

  String get label {
    switch (environment) {
      case AppEnvironment.development:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }

  static EnvironmentConfig get current {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return development;
    }
    return development;
  }

  static const development = EnvironmentConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://10.0.2.2:8080',
    wsBaseUrl: 'ws://10.0.2.2:8080',
    enableLogging: true,
  );

  static const staging = EnvironmentConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://staging.api.hush.app',
    wsBaseUrl: 'wss://staging.api.hush.app',
    enableLogging: true,
  );

  static const production = EnvironmentConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.hush.app',
    wsBaseUrl: 'wss://api.hush.app',
    enableLogging: false,
  );
}
