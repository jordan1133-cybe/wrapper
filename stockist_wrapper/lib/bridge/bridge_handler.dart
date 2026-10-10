import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/otp_service.dart';
import 'bridge_constants.dart';
import 'bridge_message.dart';

/// Routes JavaScript-to-native messages from the PWA.
///
/// Only the provisional OTP action is routed. The contract is unconfirmed;
/// see docs/project_decisions.md.
class BridgeHandler {
  final WebViewController _controller;
  final OtpService _otpService;

  BridgeHandler(this._controller, {OtpService? otpService})
    : _otpService = otpService ?? OtpService();

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
      _log(
        'Dropped malformed bridge message (not JSON or missing required fields)',
      );
      return;
    }

    _log('← Received: ${request.toLogString()}');
    _handleRequest(request);
  }

  Future<void> _handleRequest(BridgeRequest request) async {
    try {
      switch (request.action) {
        case BridgeConstants.actionStartOtpListener:
          final otpData = await _otpService.startListening(_controller);
          await _sendResponse(
            BridgeResponse.success(request.requestId, payload: otpData),
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

    final js =
        '''
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