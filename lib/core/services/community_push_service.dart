import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'huzur_api_service.dart';
import 'notification_service.dart';

/// Registers the signed-in device with Huzur API and displays in-app FCM alerts.
class CommunityPushService {
  CommunityPushService._();

  static final CommunityPushService instance = CommunityPushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final HuzurApiService _api = HuzurApiService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;
  bool _pushPermissionGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundMessage(message));
    });

    // Legacy FCM tokens are required by the current backend.
    // ignore: deprecated_member_use
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_requestPermissionAndRegister());
    });

    // Ask only after sign-in; users who never use account-backed community
    // features are not prompted for a community push permission.
    if (FirebaseAuth.instance.currentUser != null) {
      await _requestPermissionAndRegister();
    }
  }

  Future<void> _requestPermissionAndRegister() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _pushPermissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!_pushPermissionGranted) return;

      // Foreground FCM messages are rendered through the existing local
      // notification plugin so they look consistent with Huzur alerts.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      await _registerCurrentToken();
    } catch (error) {
      debugPrint('Huzur push permission setup: $error');
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      // On iOS the APNs token can arrive shortly after Firebase initialization.
      if (!kIsWeb && Platform.isIOS) {
        for (var attempt = 0; attempt < 5; attempt++) {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) break;
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      // Backend currently sends notifications using Message.token.
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
    } catch (error) {
      debugPrint('Huzur FCM token registration deferred: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    if (!_pushPermissionGranted ||
        FirebaseAuth.instance.currentUser == null ||
        token.isEmpty) {
      return;
    }

    final platform = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
    try {
      await _api.registerFcmToken(token: token, platform: platform);
    } catch (error) {
      // A later token refresh or sign-in retries registration. Never block app use.
      debugPrint('Huzur FCM token sync failed: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    if (message.data['type'] != 'dua_amin_milestone') return;

    final title = message.notification?.title ?? 'Huzur';
    final body = message.notification?.body ?? '';
    if (body.trim().isEmpty) return;

    final stableKey = message.data['notification_id']?.toString() ??
        '${message.data['post_id'] ?? 'dua'}-${message.data['milestone'] ?? ''}';

    await NotificationAndWidgetService.instance.showCommunityNotification(
      id: _stableNotificationId(stableKey),
      title: title,
      body: body,
      payload: stableKey,
    );
  }

  int _stableNotificationId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return 300000 + (hash % 500000);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    _initialized = false;
  }
}
