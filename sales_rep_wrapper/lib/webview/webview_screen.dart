import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_rep_wrapper/webview/webview_permissions.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge_handler.dart';
import '../config/app_config.dart';
import '../config/dashen_colors.dart';
import 'navigation_handler.dart';
import 'webview_file_selector.dart';

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
    _configureController();
  }

  Future<void> _configureController() async {
    await _controller.setBackgroundColor(DashenColors.surface);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setNavigationDelegate(
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
    await _controller.setOnJavaScriptAlertDialog((request) async {
      final alertUri = Uri.tryParse(request.url);
      final trustedUri = Uri.tryParse(AppConfig.webAppUrl);
      if (!mounted ||
          alertUri == null ||
          trustedUri == null ||
          alertUri.origin != trustedUri.origin) {
        return;
      }
      await _showWebAlert();
    });

    final trustedOrigin = Uri.parse(AppConfig.webAppUrl).origin;
    // Keep these after setNavigationDelegate; that setup can replace the callbacks.
    await WebViewPermissions(
      trustedOrigin: trustedOrigin,
      contextProvider: () => mounted ? context : null,
    ).attach(_controller);
    await WebViewFileSelector(
      controller: _controller,
      trustedOrigin: trustedOrigin,
      contextProvider: () => mounted ? context : null,
    ).attach();

    await _loadContent();
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

  Future<void> _showWebAlert() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DashenColors.surface,
        title: const Text(
          'Unable to complete request',
          style: TextStyle(color: DashenColors.text),
        ),
        content: const Text(
          'Something went wrong. Please try again.',
          style: TextStyle(color: DashenColors.text),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Dismiss message',
            child: ExcludeSemantics(
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor: DashenColors.lime,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('OK'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: _onBackPressed,
    child: Scaffold(
      backgroundColor: DashenColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress / 100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  DashenColors.lime,
                ),
                backgroundColor: Colors.transparent,
              ),
            if (_errorMessage != null) _errorOverlay(),
          ],
        ),
      ),
    ),
  );

  Widget _errorOverlay() => Container(
    color: DashenColors.surface,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 56, color: DashenColors.lime),
        const SizedBox(height: 24),
        const Text(
          'Unable to load',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DashenColors.text,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: DashenColors.text),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: DashenColors.lime,
            foregroundColor: DashenColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
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
