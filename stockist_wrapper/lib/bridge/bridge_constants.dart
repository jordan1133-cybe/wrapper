/// TODO(CONTRACT): Confirm all bridge constants with web team.
class BridgeConstants {
  BridgeConstants._();

  static const String channelName = 'DashenBridge';

  static const String responseCallback = 'window.DashenBridge.onResponse';

  static const String actionGetLocation = 'get_location';
  static const String actionOpenCamera = 'open_camera';
  static const String actionPickFile = 'pick_file';
  static const String actionMakeCall = 'make_call';
  static const String actionOpenMap = 'open_map';
  static const String actionOpenExternal = 'open_external';
  static const String actionStartOtpListener = 'start_otp_listener';

  static const String statusSuccess = 'success';
  static const String statusError = 'error';
  static const String statusDenied = 'denied';
  static const String statusCancelled = 'cancelled';

  static const String errorUnknownAction = 'UNKNOWN_ACTION';
  static const String errorNotImplemented = 'NOT_IMPLEMENTED';
  static const String errorInvalidArgument = 'INVALID_ARGUMENT';
  static const String errorPermissionDenied = 'PERMISSION_DENIED';
  static const String errorPermissionPermanentlyDenied =
      'PERMISSION_PERMANENTLY_DENIED';
  static const String errorServiceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String errorOperationCancelled = 'OPERATION_CANCELLED';
  static const String errorTimeout = 'TIMEOUT';
  static const String errorNative = 'NATIVE_ERROR';
}
