/// Defines the native-notification boundary without assuming an FCM or other
/// backend contract. Remote delivery is intentionally not implemented.
class NotificationService {
  Map<String, dynamic> capabilityStatus() => const {
    'localNotificationDisplay': false,
    'remoteNotificationDelivery': 'requires_backend_contract',
  };
}
