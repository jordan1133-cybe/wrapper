import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebViewPermissions {
  WebViewPermissions({required this.trustedOrigin});

  final String trustedOrigin;

  Future<void> attach(WebViewController controller) async {
    final platform = controller.platform;
    if (platform is! AndroidWebViewController) {
      _log(
        'Skipped: platform is not AndroidWebViewController '
        '(${platform.runtimeType})',
      );
      return;
    }

    await platform.setGeolocationPermissionsPromptCallbacks(
      onShowPrompt: _onGeolocationRequest,
    );
    _log('Geolocation callbacks registered for origin "$trustedOrigin"');
  }

  Future<GeolocationPermissionsResponse> _onGeolocationRequest(
    GeolocationPermissionsRequestParams request,
  ) async {
    _log('Geolocation prompt from origin "${request.origin}"');

    if (!isTrustedOrigin(request.origin, trustedOrigin)) {
      _log('Denied: origin does not match trusted "$trustedOrigin"');
      return const GeolocationPermissionsResponse(allow: false, retain: false);
    }
    final status = await Permission.locationWhenInUse.request();
    _log('Android permission result: $status');
    return GeolocationPermissionsResponse(
      allow: status.isGranted,
      retain: false,
    );
  }

  static bool isTrustedOrigin(String requestOrigin, String trusted) {
    final requestUri = Uri.tryParse(requestOrigin);
    final trustedUri = Uri.tryParse(trusted);
    if (requestUri == null || trustedUri == null) return false;
    try {
      return requestUri.origin == trustedUri.origin;
    } catch (_) {
      return false;
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WebViewPermissions] $message');
    }
  }
}
