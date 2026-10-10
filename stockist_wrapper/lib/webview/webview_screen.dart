import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge_handler.dart';
import '../config/app_config.dart';
import 'navigation_handler.dart';

const Color _brandGreen = Color(0xFF034F2A);

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  String? _errorMessage;
  String? _failedMainFrameUrl;
  String? _lastTrustedMainFrameUrl;
  bool _mainFrameLoadFailed = false;
  bool _pwaReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    BridgeHandler(_controller).register();
    _controller
      ..setBackgroundColor(_brandGreen)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationHandler.create(
          onProgress: (progress) {},
          onLoadingChanged: (isLoading) {
            if (mounted && isLoading) {
              setState(() {
                _errorMessage = null;
                _mainFrameLoadFailed = false;
              });
            }
          },
          onMainFrameStarted: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null && AppConfig.isRetryableApplicationUrl(uri)) {
              _lastTrustedMainFrameUrl = url;
            }
          },
          onError: (description, {failedUrl}) {
            if (!mounted) return;
            setState(() {
              _mainFrameLoadFailed = true;
              final parsedFailedUrl = failedUrl == null
                  ? null
                  : Uri.tryParse(failedUrl);
              if (parsedFailedUrl != null &&
                  AppConfig.isRetryableApplicationUrl(parsedFailedUrl)) {
                _failedMainFrameUrl = failedUrl;
              }
              _errorMessage = description ?? 'Failed to load the application.';
            });
          },
          onMainFrameLoadSucceeded: () {
            if (!mounted || _mainFrameLoadFailed) return;
            setState(() {
              _failedMainFrameUrl = null;
              _pwaReady = true;
            });
          },
        ),
      );

    _loadContent();
  }

  Future<void> _loadContent() async {
    if (AppConfig.useTestHarness) {
      try {
        final html = await rootBundle.loadString('assets/test_harness.html');
        await _controller.loadHtmlString(html);
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'Failed to load test harness: $e');
        }
      }
    } else {
      _controller.loadRequest(Uri.parse(AppConfig.webAppUrl));
    }
  }

  /// Reloads the failed main-frame URL when it is a trusted HTTPS application
  /// URL. Does not recreate the WebView or clear cookies/localStorage.

  void _retryFailedPage() {
    if (AppConfig.useTestHarness) {
      _loadContent();
      return;
    }

    final sourceUrl = _failedMainFrameUrl ?? _lastTrustedMainFrameUrl;
    final retryUri = AppConfig.resolveRetryUri(sourceUrl);

    String describeUrl(String? value) {
      if (value == null) return 'null';

      final uri = Uri.tryParse(value);
      if (uri == null) return 'invalid URL';

      // Log only the host and path, not query parameters.
      return '${uri.host}${uri.path}';
    }

    debugPrint('[Retry] Failed URL: ${describeUrl(_failedMainFrameUrl)}');
    debugPrint(
      '[Retry] Last trusted URL: ${describeUrl(_lastTrustedMainFrameUrl)}',
    );
    debugPrint('[Retry] Selected URL: ${describeUrl(retryUri.toString())}');

    _controller.loadRequest(retryUri);
  }

  Future<void> _onBackPressed(bool didPop, Object? _) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: _onBackPressed,
    child: Scaffold(
      backgroundColor: _brandGreen,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (!_pwaReady && _errorMessage == null) _launchCover(),
            if (_errorMessage != null) _errorOverlay(),
          ],
        ),
      ),
    ),
  );

  /// Full-screen brand hold while the WebView is still blank. The PWA splash
  /// is covered on purpose so the user never sees a black native surface.
  Widget _launchCover() => const ColoredBox(
    color: _brandGreen,
    child: Center(
      child: Image(
        image: AssetImage('assets/branding/dashen_logo.png'),
        width: 96,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Dashen',
      ),
    ),
  );

  Widget _errorOverlay() => Container(
    color: _brandGreen,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 64, color: Colors.white70),
        const SizedBox(height: 16),
        const Text(
          'Connection Error',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9EC24F), // Dashen Light Green
            foregroundColor: const Color(0xFF034F2A), // Text Color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () {
            setState(() {
              _errorMessage = null;
            });
            _retryFailedPage();
          },
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Retry Connection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
