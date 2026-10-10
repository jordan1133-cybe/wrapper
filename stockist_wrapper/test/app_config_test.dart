import 'package:flutter_test/flutter_test.dart';
import 'package:stockist_wrapper/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('active URL is https and its host is trusted', () {
      final uri = Uri.parse(AppConfig.webAppUrl);
      expect(uri.scheme, 'https');
      expect(AppConfig.trustedHosts, contains(uri.host));
    });

    test('trusted hosts exclude loopback addresses', () {
      expect(AppConfig.trustedHosts, isNot(contains('localhost')));
      expect(AppConfig.trustedHosts, isNot(contains('127.0.0.1')));
    });
  });
}
