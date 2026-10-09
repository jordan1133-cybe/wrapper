import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bridge/bridge_constants.dart';
import '../utils/native_operation_exception.dart';

/// Captures a photo without coupling the bridge to a permanent file transport.
class CameraService {
  final ImagePicker _picker;

  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<Map<String, dynamic>> capturePhoto() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      throw const NativeOperationException(
        BridgeConstants.errorPermissionPermanentlyDenied,
        'Camera permission is permanently denied. Please enable it in device settings.',
      );
    }
    if (!status.isGranted) {
      throw const NativeOperationException(
        BridgeConstants.errorPermissionDenied,
        'Camera permission was denied.',
      );
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) {
        throw const NativeOperationException(
          BridgeConstants.errorOperationCancelled,
          'Camera capture was cancelled.',
        );
      }
      return await _provisionalFilePayload(image);
    } on NativeOperationException {
      rethrow;
    } catch (_) {
      throw const NativeOperationException(
        BridgeConstants.errorNative,
        'Unable to capture photo.',
      );
    }
  }

  Future<Map<String, dynamic>> _provisionalFilePayload(XFile image) async {
    final bytes = await image.readAsBytes();
    // TODO(CONTRACT) / REQUIRES WEB TEAM CONFIRMATION: base64 is only the
    // temporary bridge representation. It may become an upload URL or another
    // agreed transport without changing CameraService's public API.
    return {
      'data': base64Encode(bytes),
      'mimeType': image.mimeType ?? 'image/jpeg',
      'fileName': image.name,
      'transport': 'base64',
    };
  }
}
