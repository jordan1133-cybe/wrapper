/// Defines the notification boundary without assuming an FCM or other backend contract.
class NotificationService {
  Map<String, dynamic> capabilityStatus() => const {
    'localNotificationDisplay': false,
    'remoteNotificationDelivery': 'requires_backend_contract',
  };
}
