import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../bridge/bridge_constants.dart';
import '../utils/native_operation_exception.dart';

/// Lets the PWA request one user-selected file through Android's system picker.
class FilePickerService {
  Future<Map<String, dynamic>> pickFile({String selectionType = 'any'}) async {
    final type = switch (selectionType) {
      'image' => FileType.image,
      'media' => FileType.media,
      'any' => FileType.any,
      _ => throw const NativeOperationException(
        BridgeConstants.errorInvalidArgument,
        'Unsupported file selection type. Expected "image", "media", or "any".',
      ),
    };

    try {
      final file = await FilePicker.pickFile(type: type);
      if (file == null) {
        throw const NativeOperationException(
          BridgeConstants.errorOperationCancelled,
          'File selection was cancelled.',
        );
      }
      final bytes = await file.readAsBytes();
      // TODO(CONTRACT) / REQUIRES WEB TEAM CONFIRMATION: this provisional
      // base64 payload must not be treated as the final upload protocol.
      return {
        'data': base64Encode(bytes),
        'mimeType': _mimeType(file.extension),
        'fileName': file.name,
        'sizeBytes': await file.length() ?? bytes.length,
        'transport': 'base64',
      };
    } on NativeOperationException {
      rethrow;
    } catch (_) {
      throw const NativeOperationException(
        BridgeConstants.errorNative,
        'Unable to select file.',
      );
    }
  }

  String _mimeType(String? extension) => switch (extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
