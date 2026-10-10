import 'dart:convert';

import 'bridge_constants.dart';

/// Provisional web-to-native request envelope.
///
/// Expected JSON from PWA:
/// ```json
/// {
///   "requestId": "unique-id",
///   "action": "start_otp_listener",
///   "payload": { ... }
/// }
/// ```
class BridgeRequest {
  final String requestId;
  final String action;
  final Map<String, dynamic> payload;

  const BridgeRequest({
    required this.requestId,
    required this.action,
    this.payload = const {},
  });

  /// Parses a JSON string into a [BridgeRequest].
  ///
  /// Returns `null` if the JSON is malformed, not an object, or missing required
  /// fields (`requestId`, `action`).
  static BridgeRequest? fromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final requestId = map['requestId'];
      final action = map['action'];
      final rawPayload = map['payload'];

      if (requestId is! String || requestId.trim().isEmpty) return null;
      if (action is! String || action.trim().isEmpty) return null;
      if (rawPayload != null && rawPayload is! Map) return null;

      return BridgeRequest(
        requestId: requestId,
        action: action,
        payload: rawPayload == null
            ? const {}
            : Map<String, dynamic>.from(rawPayload as Map),
      );
    } catch (_) {
      return null;
    }
  }

  /// Safe diagnostic string representation that avoids logging sensitive payload contents.
  String toLogString() =>
      'BridgeRequest(id: $requestId, action: $action, payloadKeys: ${payload.keys.toList()})';
}

/// Provisional native-to-web response envelope.
///
/// JSON sent to PWA:
/// ```json
/// {
///   "requestId": "unique-id",
///   "status": "success" | "error",
///   "payload": { ... },
///   "error": { "code": "...", "message": "..." }
/// }
/// ```
class BridgeResponse {
  final String requestId;
  final String status;
  final Map<String, dynamic>? payload;
  final BridgeError? error;

  const BridgeResponse({
    required this.requestId,
    required this.status,
    this.payload,
    this.error,
  });

  factory BridgeResponse.success(
    String requestId, {
    Map<String, dynamic>? payload,
  }) => BridgeResponse(
    requestId: requestId,
    status: BridgeConstants.statusSuccess,
    payload: payload,
  );

  factory BridgeResponse.error(
    String requestId, {
    required String code,
    required String message,
  }) => BridgeResponse(
    requestId: requestId,
    status: BridgeConstants.statusError,
    error: BridgeError(code: code, message: message),
  );

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'status': status,
    if (payload != null) 'payload': payload,
    if (error != null) 'error': error!.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  /// Safe diagnostic string. Payload values are intentionally not printed.
  String toLogString() {
    if (error != null) {
      return 'BridgeResponse(id: $requestId, status: $status, error: ${error!.code} - ${error!.message})';
    }
    return 'BridgeResponse(id: $requestId, status: $status, payloadKeys: ${payload?.keys.toList() ?? const []})';
  }
}

class BridgeError {
  final String code;
  final String message;

  const BridgeError({required this.code, required this.message});

  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}