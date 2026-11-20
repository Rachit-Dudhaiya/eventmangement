import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _webAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const _webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static const _channel = AndroidNotificationChannel(
    'campus_event_updates',
    'Campus event updates',
    description: 'Updates about events you are registered for.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    final options = _firebaseOptions();
    if (options == null) {
      debugPrint(
        'Push notifications are disabled. Configure the Firebase --dart-define values to enable them.',
      );
      return;
    }

    await Firebase.initializeApp(options: options);
    if (!kIsWeb) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to receive foreground notifications: $error');
      },
    );
    _initialized = true;
  }

  Future<void> registerDeviceToken(ApiClient apiClient) async {
    if (!_initialized) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // The PHP API sends through FCM HTTP v1 and requires registration tokens.
    // ignore: deprecated_member_use
    final token = await messaging.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    if (token != null && token.isNotEmpty) {
      await _saveToken(apiClient, token);
    }

    await _tokenRefreshSubscription?.cancel();
    // Keep using registration-token refreshes to match the backend token format.
    // ignore: deprecated_member_use
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (refreshedToken) => _saveRefreshedToken(apiClient, refreshedToken),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to refresh the push notification token: $error');
      },
    );
  }

  Future<void> unregisterDeviceToken(ApiClient apiClient) async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    if (!_initialized) return;

    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    if (token != null && token.isNotEmpty) {
      await apiClient.delete(
        ApiConstants.deviceToken,
        body: {'fcm_token': token},
      );
    }
  }

  Future<void> _saveRefreshedToken(ApiClient apiClient, String token) async {
    try {
      await _saveToken(apiClient, token);
    } catch (error) {
      debugPrint(
          'Unable to register the refreshed push notification token: $error');
    }
  }

  Future<void> _saveToken(ApiClient apiClient, String token) {
    return apiClient.post(
      ApiConstants.deviceToken,
      body: {'fcm_token': token, 'platform': _platform},
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final notification = message.notification;
    if (notification?.title == null || notification?.body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification!.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'campus_event_updates',
          'Campus event updates',
          channelDescription: 'Updates about events you are registered for.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
  }

  FirebaseOptions? _firebaseOptions() {
    if (_projectId.isEmpty || _messagingSenderId.isEmpty) return null;

    if (kIsWeb) {
      if (_webApiKey.isEmpty || _webAppId.isEmpty || _webVapidKey.isEmpty) {
        return null;
      }
      return const FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _webAuthDomain,
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android
          when _androidApiKey.isNotEmpty && _androidAppId.isNotEmpty =>
        const FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
        ),
      TargetPlatform.iOS
          when _iosApiKey.isNotEmpty &&
              _iosAppId.isNotEmpty &&
              _iosBundleId.isNotEmpty =>
        const FirebaseOptions(
          apiKey: _iosApiKey,
          appId: _iosAppId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          iosBundleId: _iosBundleId,
        ),
      _ => null,
    };
  }
}
