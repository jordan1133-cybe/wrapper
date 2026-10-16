import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_rep_wrapper/webview/location_services.dart';

void main() {
  const trustedOrigin = 'https://sales.example.com';

  LocationServices createServices({
    Future<bool> Function()? requestPermission,
    Future<ServiceStatus> Function()? checkServiceStatus,
    Future<LocationDialogResult?> Function()? showDialog,
    Future<bool> Function()? openSettings,
    Future<bool> Function()? waitForResume,
  }) => LocationServices(
    trustedOrigin: trustedOrigin,
    isTrustedOrigin: (requestOrigin, trusted) => requestOrigin == trusted,
    requestPermission: requestPermission ?? () async => true,
    checkServiceStatus: checkServiceStatus ?? () async => ServiceStatus.enabled,
    showLocationPrompt: showDialog ?? () async => null,
    openSettings: openSettings ?? () async => true,
    waitForResume: (_) =>
        waitForResume == null ? Future.value(true) : waitForResume(),
    hasUsableContext: () => true,
  );

  test('untrusted origin is denied', () async {
    var permissionRequested = false;
    final services = createServices(
      requestPermission: () async {
        permissionRequested = true;
        return true;
      },
    );

    expect(await services.allowRequest('https://other.example.com'), isFalse);
    expect(permissionRequested, isFalse);
  });

  test('denied location permission is denied', () async {
    var serviceChecked = false;
    final services = createServices(
      requestPermission: () async => false,
      checkServiceStatus: () async {
        serviceChecked = true;
        return ServiceStatus.enabled;
      },
    );

    expect(await services.allowRequest(trustedOrigin), isFalse);
    expect(serviceChecked, isFalse);
  });

  test('enabled location services allow without showing dialog', () async {
    var dialogShown = false;
    final services = createServices(
      checkServiceStatus: () async => ServiceStatus.enabled,
      showDialog: () async {
        dialogShown = true;
        return LocationDialogResult.turnOn;
      },
    );

    expect(await services.allowRequest(trustedOrigin), isTrue);
    expect(dialogShown, isFalse);
  });

  test(
    'not-applicable location services allow without showing dialog',
    () async {
      var dialogShown = false;
      final services = createServices(
        checkServiceStatus: () async => ServiceStatus.notApplicable,
        showDialog: () async {
          dialogShown = true;
          return LocationDialogResult.turnOn;
        },
      );

      expect(await services.allowRequest(trustedOrigin), isTrue);
      expect(dialogShown, isFalse);
    },
  );

  test('"Not now" denies the request', () async {
    final services = createServices(
      checkServiceStatus: () async => ServiceStatus.disabled,
      showDialog: () async => LocationDialogResult.notNow,
    );

    expect(await services.allowRequest(trustedOrigin), isFalse);
  });

  test('dismissed dialog denies the request', () async {
    final services = createServices(
      checkServiceStatus: () async => ServiceStatus.disabled,
      showDialog: () async => null,
    );

    expect(await services.allowRequest(trustedOrigin), isFalse);
  });

  test('returning with location on allows the request', () async {
    var serviceChecks = 0;
    var settingsOpened = false;
    final services = createServices(
      checkServiceStatus: () async =>
          serviceChecks++ == 0 ? ServiceStatus.disabled : ServiceStatus.enabled,
      showDialog: () async => LocationDialogResult.turnOn,
      openSettings: () async {
        settingsOpened = true;
        return true;
      },
      waitForResume: () async => true,
    );

    expect(await services.allowRequest(trustedOrigin), isTrue);
    expect(settingsOpened, isTrue);
    expect(serviceChecks, 2);
  });

  test('returning with location still off denies the request', () async {
    var serviceChecks = 0;
    final services = createServices(
      checkServiceStatus: () async {
        serviceChecks++;
        return ServiceStatus.disabled;
      },
      showDialog: () async => LocationDialogResult.turnOn,
      waitForResume: () async => true,
    );

    expect(await services.allowRequest(trustedOrigin), isFalse);
    expect(serviceChecks, 2);
  });

  test('resume timeout denies without re-checking service status', () async {
    var serviceChecks = 0;
    Duration? timeout;
    final services = LocationServices(
      trustedOrigin: trustedOrigin,
      isTrustedOrigin: (requestOrigin, trusted) => requestOrigin == trusted,
      requestPermission: () async => true,
      checkServiceStatus: () async {
        serviceChecks++;
        return ServiceStatus.disabled;
      },
      showLocationPrompt: () async => LocationDialogResult.turnOn,
      openSettings: () async => true,
      waitForResume: (duration) async {
        timeout = duration;
        return false;
      },
      hasUsableContext: () => true,
    );

    expect(await services.allowRequest(trustedOrigin), isFalse);
    expect(timeout, const Duration(minutes: 2));
    expect(serviceChecks, 1);
  });

  test('service status check failure allows the request', () async {
    final services = createServices(
      checkServiceStatus: () => Future.error(StateError('unavailable')),
    );

    expect(await services.allowRequest(trustedOrigin), isTrue);
  });

  test('concurrent requests reuse one permission flow and dialog', () async {
    var permissionRequests = 0;
    var dialogCount = 0;
    final dialogResult = Completer<LocationDialogResult?>();
    final services = createServices(
      requestPermission: () async {
        permissionRequests++;
        return true;
      },
      checkServiceStatus: () async => ServiceStatus.disabled,
      showDialog: () {
        dialogCount++;
        return dialogResult.future;
      },
    );

    final first = services.allowRequest(trustedOrigin);
    final second = services.allowRequest(trustedOrigin);
    await Future<void>.delayed(Duration.zero);

    expect(permissionRequests, 1);
    expect(dialogCount, 1);
    dialogResult.complete(LocationDialogResult.notNow);

    expect(await first, isFalse);
    expect(await second, isFalse);
  });
}
