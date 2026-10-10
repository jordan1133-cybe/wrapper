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
          onProgress: (progress) {},
          onLoadingChanged: (isLoading) {
            if (mounted && isLoading) {
              setState(() {
                _errorMessage = null;
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
    await _controller.loadRequest(Uri.parse(AppConfig.webAppUrl));
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
      backgroundColor: const Color(0xFF034F2A), // Dashen Green
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_errorMessage != null) _errorOverlay(),
          ],
        ),
      ),
    ),
  );

  Widget _errorOverlay() => Container(
    color: const Color(0xFF034F2A), // Dashen Green
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
            _loadContent();
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