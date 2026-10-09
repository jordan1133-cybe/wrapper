import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../bridge/bridge_constants.dart';
import '../utils/native_operation_exception.dart';

/// Obtains a foreground location only; it never starts background tracking.
class LocationService {
  Future<Map<String, dynamic>> getCurrentLocation({
    bool highAccuracy = true,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const NativeOperationException(
        BridgeConstants.errorServiceUnavailable,
        'Location services are disabled on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const NativeOperationException(
        BridgeConstants.errorPermissionPermanentlyDenied,
        'Location permission is permanently denied. Please enable it in device settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const NativeOperationException(
        BridgeConstants.errorPermissionDenied,
        'Location permission was denied.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        ),
      );

      // PROVISIONAL payload — TODO(CONTRACT): confirm exact location fields with web team.
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } on TimeoutException {
      throw const NativeOperationException(
        BridgeConstants.errorTimeout,
        'Location request timed out.',
      );
    } catch (_) {
      throw const NativeOperationException(
        BridgeConstants.errorServiceUnavailable,
        'Current location is unavailable.',
      );
    }
  }
}
