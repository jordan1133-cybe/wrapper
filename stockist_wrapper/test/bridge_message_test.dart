import 'package:flutter_test/flutter_test.dart';
import 'package:stockist_wrapper/bridge/bridge_message.dart';

void main() {
  group('BridgeRequest', () {
    test('parses a valid provisional bridge request', () {
      final request = BridgeRequest.fromJson(
        '{"requestId":"otp-1","action":"start_otp_listener","payload":{"k":"v"}}',
      );

      expect(request, isNotNull);
      expect(request!.requestId, 'otp-1');
      expect(request.action, 'start_otp_listener');
      expect(request.payload['k'], 'v');
    });

    test('rejects invalid bridge request envelopes', () {
      expect(BridgeRequest.fromJson('[]'), isNull);
      expect(BridgeRequest.fromJson('{"requestId":"otp-1"}'), isNull);
      expect(BridgeRequest.fromJson('{"action":"start_otp_listener"}'), isNull);
      expect(
        BridgeRequest.fromJson('{"requestId":"","action":"start_otp_listener"}'),
        isNull,
      );
      expect(
        BridgeRequest.fromJson(
          '{"requestId":"otp-1","action":"start_otp_listener","payload":1}',
        ),
        isNull,
      );
    });

    test('log string lists payload keys but not values', () {
      const request = BridgeRequest(
        requestId: 'req-1',
        action: 'start_otp_listener',
        payload: {'secret': 'value-123'},
      );
      expect(request.toLogString(), contains('req-1'));
      expect(request.toLogString(), contains('secret'));
      expect(request.toLogString(), isNot(contains('value-123')));
    });
  });

  group('BridgeResponse', () {
    test('serializes structured bridge errors', () {
      expect(
        BridgeResponse.error(
          'otp-1',
          code: 'UNKNOWN_ACTION',
          message: 'Nope',
        ).toJson(),
        {
          'requestId': 'otp-1',
          'status': 'error',
          'error': {'code': 'UNKNOWN_ACTION', 'message': 'Nope'},
        },
      );
    });

    test('serializes success response with payload', () {
      final json = BridgeResponse.success(
        'req-123',
        payload: {'injected': false},
      ).toJson();

      expect(json['requestId'], 'req-123');
      expect(json['status'], 'success');
      expect(json['payload'], {'injected': false});
    });

    test('success log string does not print payload values', () {
      final log = BridgeResponse.success(
        'req-1',
        payload: {'message': 'sensitive-text'},
      ).toLogString();
      expect(log, contains('message'));
      expect(log, isNot(contains('sensitive-text')));
    });
  });
}