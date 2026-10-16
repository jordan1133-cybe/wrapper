import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';


class PushService {
  PushService._();
  static final PushService instance = PushService._();

  Future<String?> init() async {
    if (Firebase.apps.isEmpty) {
      _log('Firebase not initialized; skipping push setup');
      return null;
    }
    try {
      final messaging = FirebaseMessaging.instance;

      
      final settings = await messaging.requestPermission();
      _log('permission: ${settings.authorizationStatus}');

      final token = await messaging.getToken();
      _log(token == null ? 'no token' : 'FCM token: $token');

      FirebaseMessaging.onMessage.listen((message) {
        _log('foreground message: ${message.notification?.title}');
      });
      return token;
    } catch (error) {
      _log('init failed: $error');
      return null;
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[push] $message');
  }
}