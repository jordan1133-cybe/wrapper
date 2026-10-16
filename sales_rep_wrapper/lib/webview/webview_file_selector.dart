import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_rep_wrapper/webview/webview_permissions.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/dashen_colors.dart';

enum _PhotoSource { camera, gallery }

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
        backgroundColor: DashenColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DashenColors.subtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add photo',
                  style: TextStyle(
                    color: DashenColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _photoSourceRow(
                  context: sheetContext,
                  label: 'Take photo',
                  icon: Icons.camera_alt_outlined,
                  source: _PhotoSource.camera,
                ),
                const SizedBox(height: 8),
                _photoSourceRow(
                  context: sheetContext,
                  label: 'Choose from gallery',
                  icon: Icons.photo_library_outlined,
                  source: _PhotoSource.gallery,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: DashenColors.subtle, height: 1),
                ),
                Semantics(
                  button: true,
                  label: 'Cancel photo selection',
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          foregroundColor: DashenColors.text,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    // Only the trusted PWA may launch a native image picker.
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
          style: const TextStyle(color: DashenColors.text),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DashenColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: permanentlyDenied
            ? SnackBarAction(
                label: 'Open settings',
                onPressed: () async {
                  await openAppSettings();
                },
                textColor: DashenColors.lime,
              )
            : null,
      ),
    );
  }

  Widget _photoSourceRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required _PhotoSource source,
  }) => Semantics(
    button: true,
    label: label,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 64,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context, source),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: DashenColors.photoTile,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: DashenColors.lime),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      color: DashenColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WebViewFileSelector] $message');
    }
  }
}

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
