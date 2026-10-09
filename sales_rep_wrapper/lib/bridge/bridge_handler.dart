import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/camera_service.dart';
import '../services/file_picker_service.dart';
import '../services/location_service.dart';
import '../services/otp_service.dart';
import '../utils/native_operation_exception.dart';
import 'bridge_constants.dart';
import 'bridge_message.dart';

/// Routes provisional JSON bridge requests from the PWA to native services.
class BridgeHandler {
  final WebViewController _controller;
  final LocationService _locationService;
  final CameraService _cameraService;
  final FilePickerService _filePickerService;
  final OtpService _otpService;

  BridgeHandler(
    this._controller, {
    LocationService? locationService,
    CameraService? cameraService,
    FilePickerService? filePickerService,
    OtpService? otpService,
  }) : _locationService = locationService ?? LocationService(),
       _cameraService = cameraService ?? CameraService(),
       _filePickerService = filePickerService ?? FilePickerService(),
       _otpService = otpService ?? OtpService();

  /// Registers the JavaScript channel on the [WebViewController].
  void register() {
    _controller.addJavaScriptChannel(
      BridgeConstants.channelName,
      onMessageReceived: _onMessageReceived,
    );
  }

  void _onMessageReceived(JavaScriptMessage message) {
    final request = BridgeRequest.fromJson(message.message);
    if (request == null) {
      _log('Dropped malformed bridge message (not JSON or missing required fields)');
      return;
    }

    _log('← Received: ${request.toLogString()}');
    _handleRequest(request);
  }

  Future<void> _handleRequest(BridgeRequest request) async {
    try {
      switch (request.action) {
        case BridgeConstants.actionGetLocation:
          final highAccuracy = request.payload['highAccuracy'];
          if (highAccuracy != null && highAccuracy is! bool) {
            throw const NativeOperationException(
              BridgeConstants.errorInvalidArgument,
              'highAccuracy must be a boolean.',
            );
          }
          final locationData = await _locationService.getCurrentLocation(
            highAccuracy: highAccuracy as bool? ?? true,
          );
          await _sendResponse(
            BridgeResponse.success(request.requestId, payload: locationData),
          );
          break;

        case BridgeConstants.actionOpenCamera:
          final photoData = await _cameraService.capturePhoto();
          await _sendResponse(
            BridgeResponse.success(request.requestId, payload: photoData),
          );
          break;

        case BridgeConstants.actionPickFile:
          final type = request.payload['type'];
          if (type != null && type is! String) {
            throw const NativeOperationException(
              BridgeConstants.errorInvalidArgument,
              'type must be a string.',
            );
          }
          final fileData = await _filePickerService.pickFile(
            selectionType: type as String? ?? 'any',
          );
          await _sendResponse(
            BridgeResponse.success(request.requestId, payload: fileData),
          );
          break;

        case BridgeConstants.actionStartOtpListener:
          final otpData = await _otpService.startListening();
          await _sendResponse(
            BridgeResponse.success(request.requestId, payload: otpData),
          );
          break;

        case BridgeConstants.actionMakeCall:
        case BridgeConstants.actionOpenMap:
        case BridgeConstants.actionOpenExternal:
          await _sendResponse(
            BridgeResponse.error(
              request.requestId,
              code: BridgeConstants.errorNotImplemented,
              message:
                  '${request.action} uses URL navigation rather than the bridge.',
            ),
          );
          break;

        default:
          await _sendResponse(
            BridgeResponse.error(
              request.requestId,
              code: BridgeConstants.errorUnknownAction,
              message: 'Unknown action: ${request.action}',
            ),
          );
      }
    } on NativeOperationException catch (error) {
      await _sendResponse(
        BridgeResponse.error(
          request.requestId,
          code: error.code,
          message: error.message,
        ),
      );
    } catch (_) {
      await _sendResponse(
        BridgeResponse.error(
          request.requestId,
          code: BridgeConstants.errorNative,
          message: 'The native operation failed.',
        ),
      );
    }
  }

  Future<void> _sendResponse(BridgeResponse response) async {
    _log('→ Sending: ${response.toLogString()}');

    final js = '''
      if (window.DashenBridge && typeof ${BridgeConstants.responseCallback} === 'function') {
        ${BridgeConstants.responseCallback}(${response.toJsonString()});
      }
    ''';
    try {
      await _controller.runJavaScript(js);
    } catch (error) {
      _log('Unable to send bridge response: $error');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[DashenBridge] $message');
    }
  }
}
