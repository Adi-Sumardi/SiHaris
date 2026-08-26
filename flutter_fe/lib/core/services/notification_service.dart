import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/feature_config.dart';
import 'session_service.dart';
import '../../presentation/notification/pages/notification_screen.dart';

/// Must be a top-level (or static) function, annotated for release-mode
/// tree-shaking. Android already shows a system notification automatically
/// for background/terminated messages (FCM payload includes a `notification`
/// block — see backend `FcmService::buildPayload()`), so this handler is
/// intentionally a no-op; it only exists because `firebase_messaging`
/// requires one to be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Notifikasi Penting',
        description: 'Notifikasi absensi, rekap, dan pengumuman.',
        importance: Importance.high,
      );

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

    await _initLocalNotifications();

    // Foreground message handling — Android/iOS do not auto-display a
    // system notification while the app is in the foreground, so we show
    // one ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App opened by tapping a notification while backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_openNotificationScreen);

    // App was launched (cold start) by tapping a notification.
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationScreen(initialMessage);
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Tapping the locally-shown foreground banner also opens the list.
        _pushNotificationScreen();
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['message'];

    if (title == null && body == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _openNotificationScreen(RemoteMessage message) {
    _pushNotificationScreen();
  }

  void _pushNotificationScreen() {
    final navigator = SessionService.navigatorKey.currentState;
    navigator?.push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
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
