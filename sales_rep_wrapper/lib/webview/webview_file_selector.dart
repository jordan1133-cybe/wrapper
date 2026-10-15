import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_rep_wrapper/webview/webview_permissions.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

enum _PhotoSource { camera, gallery }

/// Handles image selection requested by trusted WebView file inputs.
class WebViewFileSelector {
  WebViewFileSelector({
    required this.controller,
    required this.trustedOrigin,
    required this.contextProvider,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final WebViewController controller;
  final String trustedOrigin;
  final BuildContext? Function() contextProvider;
  final ImagePicker _imagePicker;

  Future<void> attach() async {
    final platform = controller.platform;
    if (platform is! AndroidWebViewController) return;

    await platform.setOnShowFileSelector(_onShowFileSelector);
  }

  Future<List<String>> _onShowFileSelector(FileSelectorParams params) async {
    if (!acceptsImages(params.acceptTypes)) {
      _log('Rejected file selector request without an image type');
      return [];
    }

    try {
      final currentUrl = await controller.currentUrl();
      final context = contextProvider();
      if (context == null ||
          !context.mounted ||
          currentUrl == null ||
          !_isTrustedUrl(currentUrl)) {
        _log('Rejected file selector request outside the trusted app origin');
        return [];
      }

      final source = await showModalBottomSheet<_PhotoSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, _PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, _PhotoSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
      if (!context.mounted || contextProvider()?.mounted != true) return [];
      if (source == null) return [];

      if (source == _PhotoSource.camera) {
        final permissionStatus = await Permission.camera.request();
        if (!context.mounted || contextProvider()?.mounted != true) return [];
        if (!permissionStatus.isGranted) {
          _showCameraPermissionMessage(
            context,
            permanentlyDenied: permissionStatus.isPermanentlyDenied,
          );
          return [];
        }
      }

      final image = await _imagePicker.pickImage(
        source: source == _PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (!context.mounted || contextProvider()?.mounted != true) return [];
      if (image == null) return [];

      return [Uri.file(image.path).toString()];
    } catch (_) {
      _log('Image selection failed');
      return [];
    }
  }

  bool _isTrustedUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        WebViewPermissions.isTrustedOrigin(uri.origin, trustedOrigin);
  }

  void _showCameraPermissionMessage(
    BuildContext context, {
    required bool permanentlyDenied,
  }) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          permanentlyDenied
              ? 'Camera access is disabled. Enable it in Settings.'
              : 'Camera permission was denied.',
        ),
        duration: const Duration(seconds: 4),
        action: permanentlyDenied
            ? SnackBarAction(
                label: 'Open settings',
                onPressed: () async {
                  await openAppSettings();
                },
              )
            : null,
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WebViewFileSelector] $message');
    }
  }
}

/// Returns whether an HTML file input accepts at least one image format.
bool acceptsImages(List<String> acceptTypes) {
  if (acceptTypes.isEmpty) return true;

  const imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
  for (final acceptType in acceptTypes) {
    for (final item in acceptType.split(',')) {
      final normalized = item.trim().toLowerCase();
      if (normalized == '*/*' ||
          normalized == 'image/*' ||
          (normalized.startsWith('image/') && normalized.length > 6) ||
          imageExtensions.contains(normalized)) {
        return true;
      }
    }
  }
  return false;
}
