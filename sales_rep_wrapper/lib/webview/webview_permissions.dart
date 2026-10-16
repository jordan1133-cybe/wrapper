import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'location_services.dart';

class WebViewPermissions {
  WebViewPermissions({
    required this.trustedOrigin,
    required this.contextProvider,
  }) : _locationServices = LocationServices.forApp(
         trustedOrigin: trustedOrigin,
         isTrustedOrigin: isTrustedOrigin,
         contextProvider: contextProvider,
       );

  final String trustedOrigin;
  final BuildContext? Function() contextProvider;
  final LocationServices _locationServices;

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
    final allow = await _locationServices.allowRequest(request.origin);
    _log('Geolocation request ${allow ? 'allowed' : 'denied'}');
    return GeolocationPermissionsResponse(allow: allow, retain: false);
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
