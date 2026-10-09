/// Provisional JavaScript bridge constants.
///
/// PROVISIONAL — All names in this file are provisional and must be
/// confirmed with the web team before production release.
/// TODO(CONTRACT): Confirm all bridge constants with web team.
class BridgeConstants {
  BridgeConstants._();

  // ---------------------------------------------------------------------------
  // Channel & callback names
  // ---------------------------------------------------------------------------

  /// The JavaScript channel name that the PWA uses to send messages to Flutter.
  static const String channelName = 'DashenBridge';

  /// The JavaScript function Flutter calls to deliver responses back to the PWA.
  static const String responseCallback = 'window.DashenBridge.onResponse';

  // ---------------------------------------------------------------------------
  // Action names (Web → Flutter requests)
  // ---------------------------------------------------------------------------

  static const String actionGetLocation = 'get_location';
  static const String actionOpenCamera = 'open_camera';
  static const String actionPickFile = 'pick_file';
  static const String actionMakeCall = 'make_call';
  static const String actionOpenMap = 'open_map';
  static const String actionOpenExternal = 'open_external';
  static const String actionStartOtpListener = 'start_otp_listener';

  // ---------------------------------------------------------------------------
  // Response status values
  // ---------------------------------------------------------------------------

  static const String statusSuccess = 'success';
  static const String statusError = 'error';
  static const String statusDenied = 'denied';
  static const String statusCancelled = 'cancelled';

  // ---------------------------------------------------------------------------
  // Standardized Error codes
  // ---------------------------------------------------------------------------

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
