import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
class OtpService {
  static const MethodChannel _channel = MethodChannel(
    'com.dashen.breweries/otp',
  );

  /// Requests the OTP via Android's SMS User Consent API and injects it into the WebView.
  /// Does not require SMS permissions.
  Future<Map<String, dynamic>> startListening(
    WebViewController controller,
  ) async {
    try {
      final String? otp = await _channel.invokeMethod<String>(
        'startSmsConsent',
      );
      if (otp != null && otp.isNotEmpty) {
        // We find the one-time-code input, set its value, and dispatch an Event
        // so React/Next.js registers the change, but we DO NOT submit the form.
        final script =
            '''
          (function() {
            var otpInput = document.querySelector('input[autocomplete="one-time-code"]');
            if (otpInput) {
              otpInput.value = "$otp";
              otpInput.dispatchEvent(new Event('input', { bubbles: true }));
              otpInput.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
            return false;
          })();
        ''';

        final result = await controller.runJavaScriptReturningResult(script);
        final injected = result == true;

        return {
          'listening': false,
          'implemented': true,
          'injected': injected,
          'message': injected
              ? 'OTP retrieved and injected successfully.'
              : 'OTP retrieved but no matching input field found in DOM.',
        };
      }
      return {
        'listening': false,
        'implemented': true,
        'injected': false,
        'message': 'No OTP extracted.',
      };
    } on PlatformException catch (e) {
      return {
        'listening': false,
        'implemented': true,
        'injected': false,
        'message': 'Failed to retrieve OTP: ${e.message}',
      };
    }
  }
}
