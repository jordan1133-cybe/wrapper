import 'package:flutter_test/flutter_test.dart';
import 'package:stockist_wrapper/bridge/bridge_message.dart';

void main() {
  group('BridgeRequest', () {
    test('parses a valid provisional bridge request', () {
      final request = BridgeRequest.fromJson(
        '{"requestId":"file-1","action":"pick_file","payload":{"type":"image"}}',
      );

      expect(request, isNotNull);
      expect(request!.requestId, 'file-1');
      expect(request.action, 'pick_file');
      expect(request.payload['type'], 'image');
    });

    test('rejects invalid bridge request envelopes', () {
      expect(BridgeRequest.fromJson('[]'), isNull);
      expect(BridgeRequest.fromJson('{"requestId":"file-1"}'), isNull);
      expect(BridgeRequest.fromJson('{"action":"get_location"}'), isNull);
      expect(BridgeRequest.fromJson('{"requestId":"","action":"get_location"}'), isNull);
      expect(
        BridgeRequest.fromJson(
          '{"requestId":"file-1","action":"pick_file","payload":1}',
        ),
        isNull,
      );
    });

    test('generates safe log string without dumping sensitive content', () {
      const request = BridgeRequest(
        requestId: 'req-1',
        action: 'get_location',
        payload: {'highAccuracy': true},
      );
      expect(request.toLogString(), contains('req-1'));
      expect(request.toLogString(), contains('get_location'));
      expect(request.toLogString(), contains('highAccuracy'));
    });
  });

  group('BridgeResponse', () {
    test('serializes structured bridge errors', () {
      expect(
        BridgeResponse.error(
          'file-1',
          code: 'NOT_IMPLEMENTED',
          message: 'Not ready',
        ).toJson(),
        {
          'requestId': 'file-1',
          'status': 'error',
          'error': {'code': 'NOT_IMPLEMENTED', 'message': 'Not ready'},
        },
      );
    });

    test('serializes success response with payload', () {
      final json = BridgeResponse.success(
        'req-123',
        payload: {'latitude': 9.034, 'longitude': 38.764},
      ).toJson();

      expect(json['requestId'], 'req-123');
      expect(json['status'], 'success');
      expect(json['payload']['latitude'], 9.034);
    });

    test('serializes permission denied and cancelled responses', () {
      final denied = BridgeResponse.denied('req-1', message: 'User denied').toJson();
      expect(denied['status'], 'denied');
      expect(denied['error']['code'], 'PERMISSION_DENIED');

      final cancelled = BridgeResponse.cancelled('req-2').toJson();
      expect(cancelled['status'], 'cancelled');
      expect(cancelled['error']['code'], 'OPERATION_CANCELLED');
    });

    test('sanitizes large base64 payload in toLogString()', () {
      final largeData = 'A' * 200;
      final response = BridgeResponse.success(
        'photo-1',
        payload: {'data': largeData, 'transport': 'base64'},
      );

      final logString = response.toLogString();
      expect(logString, contains('[base64 200 chars]'));
      expect(logString, isNot(contains(largeData)));
    });
  });
}
