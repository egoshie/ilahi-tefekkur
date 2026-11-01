import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class HuzurSupportNotificationBridge {
  HuzurSupportNotificationBridge._();
  static final HuzurSupportNotificationBridge instance =
      HuzurSupportNotificationBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.ilahi.tefekkur/native_bridge');

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final List<void Function(String)> _listeners = [];
  StreamSubscription<String>? _tokenSubscription;
  String? _token;
  bool _localReady = false;
  bool _listening = false;

  String? get currentToken => _token;

  void addListener(void Function(String) listener) {
    _listeners.add(listener);
    _initializeTokenListener();
  }

  Future<void> _initializeTokenListener() async {
    if (_listening) return;
    _listening = true;

    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _publishToken(token);
      }

      _tokenSubscription = messaging.onTokenRefresh.listen(_publishToken);
    } catch (error) {
      _listening = false;
    }
  }

  void _publishToken(String value) {
    final clean = value.trim();
    if (clean.isEmpty || clean == _token) return;
    _token = clean;
    for (final listener in List<void Function(String)>.from(_listeners)) {
      try {
        listener(clean);
      } catch (_) {}
    }
  }

  Future<String> permissionStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
        case AuthorizationStatus.denied:
          return 'denied';
        case AuthorizationStatus.deniedPermanently:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'notDetermined';
      }
    } catch (_) {}
    return 'notDetermined';
  }

  Future<bool> openSettings() async {
    try {
      return await _channel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> showDeveloperReply({
    required String message,
    String? shortCode,
  }) async {
    try {
      if (!_localReady) {
        const initialization = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        );
        await _local.initialize(initialization);
        _localReady = true;
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'huzur_support_channel',
          'Huzur Canli Destek',
          channelDescription: 'Gelistirici mesajlari',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      await _local.show(
        id,
        'Ege size yazdi',
        message,
        details,
        payload: shortCode ?? '',
      );
    } catch (_) {
      // Bildirim izni yoksa sessizce devam et.
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _listening = false;
  }
}

extension NotificationAndWidgetServiceSupport on NotificationAndWidgetService {
  void addTokenRefreshListener(void Function(String) listener) {
    HuzurSupportNotificationBridge.instance.addListener(listener);
  }

  Future<String> checkPermissionStatus() {
    return HuzurSupportNotificationBridge.instance.permissionStatus();
  }

  String? get currentPushToken =>
      HuzurSupportNotificationBridge.instance.currentToken;

  Future<void> showEgeReplyNotification({
    required String messageText,
    String? shortCode,
  }) {
    return HuzurSupportNotificationBridge.instance.showDeveloperReply(
      message: messageText,
      shortCode: shortCode,
    );
  }

  Future<bool> openSystemNotificationSettings() {
    return HuzurSupportNotificationBridge.instance.openSettings();
  }
}
