/// Central configuration for the Dashen Sales Rep wrapper.
///
/// All environment URLs, trusted host definitions, and feature flags
/// are centralized here for safe transitions between dev and prod.
class AppConfig {
  AppConfig._();

  /// PROVISIONAL — Replace with the confirmed Sales Rep development PWA URL.
  /// TODO(CONTRACT): Update with real Sales Rep PWA dev URL.
  static const String devUrl = 'https://flutter.dev';

  /// PROVISIONAL — Replace with the confirmed Sales Rep production PWA URL.
  /// TODO(CONTRACT): Update with real Sales Rep PWA prod URL.
  static const String prodUrl = 'https://flutter.dev';

  /// Active URL loaded by the wrapper.
  static const String webAppUrl = devUrl;

  /// Application display name.
  static const String appName = 'Dashen Sales Rep';

  /// DEVELOPMENT ONLY — Native bridge test harness flag.
  /// When true, loads the local assets/test_harness.html to verify native bridge actions.
  /// Must be false in production builds.
  static const bool useTestHarness = false;

  /// List of trusted hosts allowed to load inside the WebView.
  /// Any HTTP/HTTPS navigation targeting a host NOT in this list is
  /// intercepted and opened in the external system browser.
  /// TODO(CONTRACT): Confirm complete list of allowed PWA domains with web team.
  static const List<String> trustedHosts = [
    'flutter.dev',
    'localhost',
    '127.0.0.1',
  ];
}
