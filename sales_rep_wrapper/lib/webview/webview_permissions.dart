import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Lets the page use the phone's location, but only the trusted app origin.
class WebViewPermissions {
  WebViewPermissions({required this.trustedOrigin});

  /// e.g. https://sales.dashensalestracking.wearecerta.app
  final String trustedOrigin;

  Future<void> attach(WebViewController controller) async {
    final platform = controller.platform;
    if (platform is! AndroidWebViewController) return;

    await platform.setGeolocationPermissionsPromptCallbacks(
      onShowPrompt: _onGeolocationRequest,
    );
  }

  Future<GeolocationPermissionsResponse> _onGeolocationRequest(
    GeolocationPermissionsRequestParams request,
  ) async {
    if (request.origin != trustedOrigin) {
      return const GeolocationPermissionsResponse(allow: false, retain: false);
    }
    // Android's own permission dialog (first time only).
    final status = await Permission.locationWhenInUse.request();
    return GeolocationPermissionsResponse(
      allow: status.isGranted,
      retain: false,
    );
  }
}