import 'package:flutter_test/flutter_test.dart';
import 'package:stockist_wrapper/config/app_config.dart';

void main() {
  group('AppConfig retry URL policy', () {
    test('accepts HTTPS URLs on approved application hosts', () {
      expect(
        AppConfig.isRetryableApplicationUrl(
          Uri.parse('https://dashensalestracking.wearecerta.app/stockists'),
        ),
        isTrue,
      );
      expect(
        AppConfig.isRetryableApplicationUrl(
          Uri.parse(
            'https://stockist.dashensalestracking.wearecerta.app/orders?id=1',
          ),
        ),
        isTrue,
      );
    });

    test('rejects untrusted, non-HTTPS, and loopback URLs', () {
      expect(
        AppConfig.isRetryableApplicationUrl(
          Uri.parse('http://dashensalestracking.wearecerta.app/login'),
        ),
        isFalse,
      );
      expect(
        AppConfig.isRetryableApplicationUrl(
          Uri.parse('https://evil.example/phish'),
        ),
        isFalse,
      );
      expect(
        AppConfig.isRetryableApplicationUrl(Uri.parse('https://localhost/app')),
        isFalse,
      );
      expect(
        AppConfig.isRetryableApplicationUrl(Uri.parse('https://127.0.0.1/app')),
        isFalse,
      );
    });

    test('retries a trusted failed URL and falls back otherwise', () {
      const failed = 'https://dashensalestracking.wearecerta.app/campaigns';
      expect(AppConfig.resolveRetryUri(failed), Uri.parse(failed));
      expect(
        AppConfig.resolveRetryUri('https://evil.example/steal'),
        Uri.parse(AppConfig.webAppUrl),
      );
      expect(AppConfig.resolveRetryUri(null), Uri.parse(AppConfig.webAppUrl));
      expect(
        AppConfig.resolveRetryUri('not a url'),
        Uri.parse(AppConfig.webAppUrl),
      );
    });
  });
}
