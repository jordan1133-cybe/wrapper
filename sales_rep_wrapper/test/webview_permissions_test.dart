import 'package:flutter_test/flutter_test.dart';
import 'package:sales_rep_wrapper/webview/webview_permissions.dart';

void main() {
  const trusted = 'https://sales.dashensalestracking.wearecerta.app';

  group('isTrustedOrigin', () {
    test('exact match (no trailing slash)', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app',
          trusted,
        ),
        isTrue,
      );
    });

    test('request origin with trailing slash', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app/',
          trusted,
        ),
        isTrue,
      );
    });

    test('trusted has trailing slash, request does not', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app',
          'https://sales.dashensalestracking.wearecerta.app/',
        ),
        isTrue,
      );
    });

    test('both have trailing slash', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app/',
          'https://sales.dashensalestracking.wearecerta.app/',
        ),
        isTrue,
      );
    });

    test('different host is rejected', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://evil.example.com',
          trusted,
        ),
        isFalse,
      );
    });

    test('subdomain-suffix attack is rejected', () {
      // Ensures "wearecerta.app.evil.com" doesn't match
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app.evil.com',
          trusted,
        ),
        isFalse,
      );
    });

    test('http scheme is rejected when trusted is https', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'http://sales.dashensalestracking.wearecerta.app',
          trusted,
        ),
        isFalse,
      );
    });

    test('explicit port on request is rejected (default port trusted)', () {
      // https default port is 443; explicit :443 should still match via
      // Uri.origin normalisation, but :8080 should not.
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app:8080',
          trusted,
        ),
        isFalse,
      );
    });

    test('explicit default port (:443) matches https origin', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app:443',
          trusted,
        ),
        isTrue,
      );
    });

    test('empty string is rejected', () {
      expect(
        WebViewPermissions.isTrustedOrigin('', trusted),
        isFalse,
      );
    });

    test('garbage string is rejected', () {
      expect(
        WebViewPermissions.isTrustedOrigin('not-a-url', trusted),
        isFalse,
      );
    });

    test('"null" string is rejected', () {
      expect(
        WebViewPermissions.isTrustedOrigin('null', trusted),
        isFalse,
      );
    });

    test('request with path still matches on origin', () {
      expect(
        WebViewPermissions.isTrustedOrigin(
          'https://sales.dashensalestracking.wearecerta.app/onboarding/step2',
          trusted,
        ),
        isTrue,
      );
    });
  });
}
