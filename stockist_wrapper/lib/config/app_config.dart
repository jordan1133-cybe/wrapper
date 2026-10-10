class AppConfig {
  AppConfig._();

  /// Live Stockist deployment used for the working Android demo.
  ///
  /// The deployment currently serves the Stockist portal from the apex host.
  static const String devUrl =
      'https://dashensalestracking.wearecerta.app/login';

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

  /// List of trusted hosts allowed to load inside the WebView.
  /// Any HTTP/HTTPS navigation targeting a host NOT in this list is
  /// intercepted and opened in the external system browser.
  static const List<String> trustedHosts = [
    'dashensalestracking.wearecerta.app',
    'stockist.dashensalestracking.wearecerta.app',
  ];
}