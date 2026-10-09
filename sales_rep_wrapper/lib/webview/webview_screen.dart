import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge_handler.dart';
import '../config/app_config.dart';
import 'navigation_handler.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    BridgeHandler(_controller).register();
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationHandler.create(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onLoadingChanged: (isLoading) {
            if (mounted) {
              setState(() {
                _isLoading = isLoading;
                if (isLoading) _errorMessage = null;
              });
            }
          },
          onError: (description) {
            if (mounted) {
              setState(
                () => _errorMessage =
                    description ?? 'Failed to load the application.',
              );
            }
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
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress / 100,
                backgroundColor: Colors.transparent,
              ),
            if (_errorMessage != null) _errorOverlay(),
          ],
        ),
      ),
    ),
  );

  Widget _errorOverlay() => Container(
    color: Colors.white,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Unable to load',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_errorMessage!, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => _errorMessage = null);
            _loadContent();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
