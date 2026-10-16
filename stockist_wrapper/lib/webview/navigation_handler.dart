import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';

class NavigationHandler {
  NavigationHandler._();

  static NavigationDelegate create({
    required void Function(int progress) onProgress,
    required void Function(bool isLoading) onLoadingChanged,
    required void Function(String? errorDescription) onError,
  }) => NavigationDelegate(
    onPageStarted: (url) {
      onLoadingChanged(true);
      _log('Page started: $url');
    },
    onProgress: onProgress,
    onPageFinished: (url) {
      onLoadingChanged(false);
      _log('Page finished: $url');
    },
    onWebResourceError: (error) {
      if (error.isForMainFrame == true) {
        _log('Main-frame resource error: ${error.description}');
        onError(error.description);
      }
    },
    onNavigationRequest: _handleNavigationRequest,
  );

  static NavigationDecision _handleNavigationRequest(
    NavigationRequest request,
  ) {
    final url = request.url;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _log('Blocked invalid navigation URI: $url');
      return NavigationDecision.prevent;
    }

    _log('Navigation request: $url');

    // `intent:` URIs can target arbitrary activities, so keep them blocked.
    if (const {'tel', 'mailto', 'sms', 'geo'}.contains(uri.scheme) ||
        _isMapUrl(uri)) {
      _launchExternal(uri);
      return NavigationDecision.prevent;
    }

    if (_isInternalUrl(uri)) {
      return NavigationDecision.navigate;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      _launchExternal(uri);
      return NavigationDecision.prevent;
    }

    _log('Blocked untrusted URL scheme: $url');
    return NavigationDecision.prevent;
  }

  static bool _isInternalUrl(Uri uri) {
    if (uri.host.isEmpty) return false;

    final activeAppUri = Uri.tryParse(AppConfig.webAppUrl);
    if (activeAppUri != null && uri.host == activeAppUri.host) {
      return true;
    }

    return AppConfig.trustedHosts.contains(uri.host.toLowerCase());
  }

  static bool _isMapUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('maps.google.com') ||
        host.contains('maps.app.goo.gl') ||
        host.contains('openstreetmap.org');
  }

  static Future<void> _launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _log('No external application available to handle: $uri');
      }
    } catch (error) {
      _log('Error launching external URL: $error');
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Navigation] $message');
    }
  }
}
