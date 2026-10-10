/// TODO(CONTRACT): Every value here is provisional until the PWA team confirms
/// the bridge contract. Only the OTP action is currently routed.
class BridgeConstants {
  BridgeConstants._();

  static const String channelName = 'DashenBridge';

  static const String responseCallback = 'window.DashenBridge.onResponse';

  /// Provisional, unconfirmed action name for starting the OTP listener.
  static const String actionStartOtpListener = 'start_otp_listener';

  static const String statusSuccess = 'success';
  static const String statusError = 'error';

  static const String errorUnknownAction = 'UNKNOWN_ACTION';
  static const String errorNative = 'NATIVE_ERROR';
}