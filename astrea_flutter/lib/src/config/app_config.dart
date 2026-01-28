import 'dart:convert';

import 'package:flutter/services.dart';

/// Application configuration loaded from assets/config.json
/// Supports environment-specific configs via --dart-define=ENV=production
class AppConfig {
  // Constants
  static const String _defaultApiUrl = 'http://localhost:8080';
  static const String _defaultEnv = 'development';

  // Static fields
  static AppConfig? _instance;

  // Instance fields
  final String apiUrl;
  final String environment;

  // Private constructor
  const AppConfig._({
    required this.apiUrl,
    required this.environment,
  });

  // Getters
  /// Get the singleton instance. Must call [load] first.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig not loaded. Call AppConfig.load() first.');
    }
    return config;
  }

  /// Check if running in production
  bool get isProduction => environment == 'production';

  /// Check if running in development
  bool get isDevelopment => environment == 'development';

  // Public methods
  /// Load configuration from assets.
  /// Use --dart-define=ENV=production to switch environments.
  static Future<AppConfig> load() async {
    if (_instance != null) return _instance!;

    const env = String.fromEnvironment('ENV', defaultValue: _defaultEnv);

    final configPath = switch (env) {
      'production' => 'assets/config.production.json',
      _ => 'assets/config.development.json',
    };

    _instance =
        await _loadFromPath(configPath, env) ??
        await _loadFromPath('assets/config.json', env) ??
        const AppConfig._(
          apiUrl: _defaultApiUrl,
          environment: _defaultEnv,
        );

    return _instance!;
  }

  // Private methods
  static Future<AppConfig?> _loadFromPath(String path, String env) async {
    try {
      final configString = await rootBundle.loadString(path);
      final configJson = json.decode(configString) as Map<String, dynamic>;

      return AppConfig._(
        apiUrl: configJson['apiUrl'] as String? ?? _defaultApiUrl,
        environment: configJson['environment'] as String? ?? env,
      );
    } catch (_) {
      return null;
    }
  }
}
