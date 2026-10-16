import 'package:flutter_test/flutter_test.dart';
import 'package:sales_rep_wrapper/bridge/bridge_message.dart';

void main() {
  group('BridgeRequest', () {
    test('parses a valid request', () {
      final request = BridgeRequest.fromJson(
        '{"requestId":"otp-1","action":"start_otp_listener","payload":{}}',
      );

      expect(request, isNotNull);
      expect(request!.requestId, 'otp-1');
      expect(request.action, 'start_otp_listener');
      expect(request.payload, isEmpty);
    });

    test('rejects malformed requests', () {
      expect(BridgeRequest.fromJson('[]'), isNull);
      expect(BridgeRequest.fromJson('{"requestId":"otp-1"}'), isNull);
      expect(BridgeRequest.fromJson('{"action":"start_otp_listener"}'), isNull);
      expect(
        BridgeRequest.fromJson(
          '{"requestId":"otp-1","action":"start_otp_listener","payload":1}',
        ),
        isNull,
      );
    });

    test('does not include payload values in diagnostic output', () {
      const request = BridgeRequest(
        requestId: 'otp-1',
        action: 'start_otp_listener',
        payload: {'token': 'secret'},
      );

      expect(request.toLogString(), contains('token'));
      expect(request.toLogString(), isNot(contains('secret')));
    });
  });

  group('BridgeResponse', () {
    test('serializes an error response', () {
      expect(
        BridgeResponse.error(
          'otp-1',
          code: 'UNKNOWN_ACTION',
          message: 'Unknown action: invalid',
        ).toJson(),
        {
          'requestId': 'otp-1',
          'status': 'error',
          'error': {
            'code': 'UNKNOWN_ACTION',
            'message': 'Unknown action: invalid',
          },
        },
      );
    });

    test('serializes success response with payload', () {
      final json = BridgeResponse.success(
        'otp-1',
        payload: {'listening': false},
      ).toJson();

      expect(json['requestId'], 'otp-1');
      expect(json['status'], 'success');
      expect(json['payload']['listening'], isFalse);
    });

    test('sanitizes large base64 payload in log output', () {
      final data = 'A' * 200;
      final response = BridgeResponse.success(
        'photo-1',
        payload: {'data': data},
      );

      expect(response.toLogString(), contains('[base64 200 chars]'));
      expect(response.toLogString(), isNot(contains(data)));
    });
  });
}
