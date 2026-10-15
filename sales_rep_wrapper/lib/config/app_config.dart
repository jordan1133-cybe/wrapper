
class AppConfig {
  AppConfig._();

  
  static const String devUrl = 'https://sales.dashensalestracking.wearecerta.app/';

  static const String prodUrl = 'https://flutter.dev';


  static const String webAppUrl = devUrl;

 
  static const String appName = 'Dashen Sales Rep';

 
  static const bool useTestHarness = false;


  static const List<String> trustedHosts = [
    'flutter.dev',
    'localhost',
    '127.0.0.1',
  ];
}
