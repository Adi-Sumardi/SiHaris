import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/feature_config.dart';

class NotificationService {
  FirebaseMessaging? _firebaseMessaging;

  /// Returns true if push notifications are enabled and available.
  bool get isEnabled => FeatureConfig.enablePushNotification;

  Future<void> initialize() async {
    if (!FeatureConfig.enablePushNotification) {
      debugPrint('Push notifications are disabled via FeatureConfig');
      return;
    }

    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission
    await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message while in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }
    });
  }

  Future<String?> getToken() async {
    if (!FeatureConfig.enablePushNotification || _firebaseMessaging == null) {
      return null;
    }

    try {
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging!.getAPNSToken();
        if (apnsToken == null) {
          // Wait a bit for APNS token
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging!.getAPNSToken();
        }
      }
      return await _firebaseMessaging!.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Stream<String> get onTokenRefresh {
    if (!FeatureConfig.enablePushNotification || _firebaseMessaging == null) {
      return const Stream.empty();
    }
    return _firebaseMessaging!.onTokenRefresh;
  }
}
