import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/dashen_colors.dart';

const locationSettingsChannelName = 'com.dashen.sales_rep/location_settings';

enum LocationDialogResult { notNow, turnOn, contextUnavailable }

class LocationServices {
  LocationServices({
    required this.trustedOrigin,
    required this.isTrustedOrigin,
    required this.requestPermission,
    required this.checkServiceStatus,
    required this.showLocationPrompt,
    required this.openSettings,
    required this.waitForResume,
    required this.hasUsableContext,
  });

  factory LocationServices.forApp({
    required String trustedOrigin,
    required bool Function(String requestOrigin, String trustedOrigin)
    isTrustedOrigin,
    required BuildContext? Function() contextProvider,
  }) {
    bool hasUsableContext() {
      final context = contextProvider();
      return context != null && context.mounted;
    }

    return LocationServices(
      trustedOrigin: trustedOrigin,
      isTrustedOrigin: isTrustedOrigin,
      requestPermission: () async =>
          (await Permission.locationWhenInUse.request()).isGranted,
      checkServiceStatus: () => Permission.locationWhenInUse.serviceStatus,
      showLocationPrompt: () => _presentLocationDialog(contextProvider),
      openSettings: _openLocationSettings,
      waitForResume: _waitForResume,
      hasUsableContext: hasUsableContext,
    );
  }

  final String trustedOrigin;
  final bool Function(String requestOrigin, String trustedOrigin)
  isTrustedOrigin;
  final Future<bool> Function() requestPermission;
  final Future<ServiceStatus> Function() checkServiceStatus;
  final Future<LocationDialogResult?> Function() showLocationPrompt;
  final Future<bool> Function() openSettings;
  final Future<bool> Function(Duration timeout) waitForResume;
  final bool Function() hasUsableContext;

  Future<bool>? _inFlightRequest;

  Future<bool> allowRequest(String requestOrigin) {
    if (!isTrustedOrigin(requestOrigin, trustedOrigin)) {
      return Future.value(false);
    }
    final inFlightRequest = _inFlightRequest;
    if (inFlightRequest != null) return inFlightRequest;

    final request = _decide();
    _inFlightRequest = request;
    unawaited(
      request.then<void>(
        (_) => _clearInFlightRequest(request),
        onError: (Object _, StackTrace _) => _clearInFlightRequest(request),
      ),
    );
    return request;
  }

  Future<bool> _decide() async {
    bool permissionGranted;
    try {
      permissionGranted = await requestPermission();
    } catch (error) {
      hasUsableContext();
      _log('Location permission request failed: $error');
      return false;
    }
    final hasContextAfterPermission = hasUsableContext();
    if (!permissionGranted) return false;
    if (!hasContextAfterPermission) return true;

    ServiceStatus serviceStatus;
    try {
      serviceStatus = await checkServiceStatus();
    } catch (error) {
      hasUsableContext();
      _log('Location service status check failed: $error');
      return true;
    }
    if (!hasUsableContext()) return true;
    if (serviceStatus != ServiceStatus.disabled) return true;

    final result = await showLocationPrompt();
    if (!hasUsableContext()) return true;
    if (result == LocationDialogResult.contextUnavailable) return true;
    if (result != LocationDialogResult.turnOn) return false;

    final resumed = waitForResume(const Duration(minutes: 2));
    final settingsOpened = await openSettings();
    if (!hasUsableContext()) return true;
    if (!settingsOpened) return false;

    final didResume = await resumed;
    if (!hasUsableContext()) return true;
    if (!didResume) return false;

    try {
      final statusAfterSettings = await checkServiceStatus();
      if (!hasUsableContext()) return true;
      return statusAfterSettings != ServiceStatus.disabled;
    } catch (error) {
      hasUsableContext();
      _log('Location service status re-check failed: $error');
      return true;
    }
  }

  void _clearInFlightRequest(Future<bool> request) {
    if (identical(_inFlightRequest, request)) {
      _inFlightRequest = null;
    }
  }

  static Future<LocationDialogResult?> _presentLocationDialog(
    BuildContext? Function() contextProvider,
  ) {
    final context = contextProvider();
    if (context == null || !context.mounted) {
      return Future.value(LocationDialogResult.contextUnavailable);
    }

    return showDialog<LocationDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: DashenColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Turn on location',
                style: TextStyle(
                  color: DashenColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Location is turned off on this phone. Turn it on to capture the stockist's location.",
                style: TextStyle(color: DashenColors.text, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  Semantics(
                    button: true,
                    label: 'Not now',
                    child: ExcludeSemantics(
                      child: TextButton(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          LocationDialogResult.notNow,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: DashenColors.text,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Not now'),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Turn on location',
                    child: ExcludeSemantics(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          LocationDialogResult.turnOn,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: DashenColors.lime,
                          foregroundColor: DashenColors.surface,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Turn on'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> _openLocationSettings() async {
    try {
      final opened = await const MethodChannel(locationSettingsChannelName)
          .invokeMethod<bool>('openLocationSettings');
      if (opened == true) return true;
    } catch (error) {
      _log('Could not open Location settings directly: $error');
    }
    return openAppSettings();
  }

  static Future<bool> _waitForResume(Duration timeout) async {
    final binding = WidgetsBinding.instance;
    final observer = _ResumeObserver();
    binding.addObserver(observer);
    final timer = Timer(timeout, () => observer.complete(false));
    try {
      return await observer.future;
    } finally {
      timer.cancel();
      binding.removeObserver(observer);
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocationServices] $message');
    }
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  final Completer<bool> _completer = Completer<bool>();
  bool _leftResumedState = false;

  Future<bool> get future => _completer.future;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _leftResumedState = true;
    } else if (_leftResumedState) {
      complete(true);
    }
  }

  void complete(bool didResume) {
    if (!_completer.isCompleted) _completer.complete(didResume);
  }
}
