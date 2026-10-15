import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Lets the page use the phone's location, but only the trusted app origin.
class WebViewPermissions {
  WebViewPermissions({required this.trustedOrigin});

  /// e.g. https://sales.dashensalestracking.wearecerta.app
  final String trustedOrigin;

  /// Registers geolocation permission callbacks on the Android platform
  /// controller.
  ///
  /// **Must be called after [WebViewController.setNavigationDelegate]** so
  /// that the geolocation callbacks are not overwritten when the delegate
  /// installs its own [WebChromeClient].
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
    // Android's own permission dialog (first time only).
    final status = await Permission.locationWhenInUse.request();
    _log('Android permission result: $status');
    return GeolocationPermissionsResponse(
      allow: status.isGranted,
      retain: false,
    );
  }

  /// Compares [requestOrigin] (from the WebView) against [trusted] using
  /// proper URI origin semantics (scheme + host + port).
  ///
  /// This is a pure function so it can be unit-tested independently.
  static bool isTrustedOrigin(String requestOrigin, String trusted) {
    final requestUri = Uri.tryParse(requestOrigin);
    final trustedUri = Uri.tryParse(trusted);
    if (requestUri == null || trustedUri == null) return false;
    // Uri.origin throws for non-absolute URIs with no scheme, so guard.
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
