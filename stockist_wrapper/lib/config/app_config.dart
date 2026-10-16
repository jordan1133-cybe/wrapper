class AppConfig {
  AppConfig._();

  static const String devUrl =
      'https://dashensalestracking.wearecerta.app/login';

  static const String prodUrl =
      'https://stockist.dashensalestracking.wearecerta.app';

  static const String webAppUrl = devUrl;

  static const String appName = 'Dashen Breweries Sales Incentive App';

  static const List<String> trustedHosts = [
    'dashensalestracking.wearecerta.app',
    'stockist.dashensalestracking.wearecerta.app',
  ];
}
