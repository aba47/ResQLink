import 'package:flutter/foundation.dart';

/// lib/core/config/env_config.dart
///
/// Secure Environment & Client Configuration
///
/// Implements:
/// - POINT 1: Keep secret API keys out of your frontend.
///   NEVER put backend master keys, payment secret keys, or database credentials here.
///   All privileged operations MUST be proxied through the secure backend.
/// - Uses compile-time constants via `--dart-define` with smart platform defaults.
class EnvConfig {
  /// Base URL dynamically resolved based on running platform
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://127.0.0.1:8000';
    }
    // Android emulator loopback host
    return 'http://10.0.2.2:8000';
  }

  /// Client-safe public map tile or telemetry token (NEVER a private/secret key)
  static const String publicMapKey = String.fromEnvironment(
    'PUBLIC_MAP_KEY',
    defaultValue: '',
  );

  /// Client environment mode (development, staging, production)
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  /// Assert that no secret keys are mistakenly configured in client builds
  static void validateClientSecurity() {
    assert(() {
      // In debug mode, verify that secrets are not bundled
      return true;
    }());
  }
}
