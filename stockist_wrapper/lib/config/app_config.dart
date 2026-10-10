class AppConfig {
  AppConfig._();

  /// Live Stockist deployment used for the working Android demo.
  ///
  /// The deployment currently serves the Stockist portal from the apex host.
  static const String devUrl = 'https://dashensalestracking.wearecerta.app';

  /// Intended Stockist production portal origin.
  ///
  /// BLOCKED: its TLS certificate currently does not match this hostname
  /// (Chromium net::ERR_CERT_COMMON_NAME_INVALID / net error -200).
  static const String prodUrl =
      'https://stockist.dashensalestracking.wearecerta.app';

  /// Active URL loaded by the wrapper. Keep this on the live apex deployment
  /// until the Stockist subdomain certificate is corrected by deployment.
  static const String webAppUrl = devUrl;

  /// Application display name.
  static const String appName = 'Dashen Stockist';

  /// DEVELOPMENT ONLY — Native bridge test harness flag.
  /// Set to false to load the real PWA.
  static const bool useTestHarness = false;

  /// List of trusted hosts allowed to load inside the WebView.
  /// Any HTTP/HTTPS navigation targeting a host NOT in this list is
  /// intercepted and opened in the external system browser.
  static const List<String> trustedHosts = [
    'dashensalestracking.wearecerta.app',
    'stockist.dashensalestracking.wearecerta.app',
    'localhost',
    '127.0.0.1',
  ];

  /// Application hosts that may be retried after a main-frame load failure.
  ///
  /// Loopback hosts remain in [trustedHosts] for local harness navigation, but
  /// Retry must not load arbitrary or non-HTTPS URLs.
  static const List<String> retryableApplicationHosts = [
    'dashensalestracking.wearecerta.app',
    'stockist.dashensalestracking.wearecerta.app',
  ];

  /// Returns true when [uri] is an HTTPS URL on an approved application host.
  static bool isRetryableApplicationUrl(Uri uri) {
    if (uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return retryableApplicationHosts.contains(uri.host.toLowerCase());
  }

  /// Picks a Retry target from a failed main-frame URL, or falls back to the
  /// configured application entry URL when the failed URL is missing/untrusted.
  static Uri resolveRetryUri(String? failedUrl) {
    final parsed = failedUrl == null ? null : Uri.tryParse(failedUrl);
    if (parsed != null && isRetryableApplicationUrl(parsed)) {
      return parsed;
    }
    return Uri.parse(webAppUrl);
  }
}
