class BridgeConstants {
  BridgeConstants._();

  static const String channelName = 'DashenBridge';
  static const String responseCallback = 'window.DashenBridge.onResponse';

  static const String actionStartOtpListener = 'start_otp_listener';

  static const String statusSuccess = 'success';
  static const String statusError = 'error';

  static const String errorUnknownAction = 'UNKNOWN_ACTION';
  static const String errorNative = 'NATIVE_ERROR';
}
