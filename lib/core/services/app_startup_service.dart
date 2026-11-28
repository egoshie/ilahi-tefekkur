import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'community_push_service.dart';
import 'notification_service.dart';

/// Starts non-visual services after Huzur has drawn its first frame.
/// Firebase-dependent screens can await [ensureFirebaseReady].
class AppStartupService {
  AppStartupService._();

  static Future<void>? _firebaseReady;
  static Future<void>? _backgroundReady;

  static Future<void> ensureFirebaseReady() {
    return _firebaseReady ??= _initializeFirebase();
  }

  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleDeviceCheckProvider(),
    );
  }

  static Future<void> initializeBackgroundServices() {
    return _backgroundReady ??= _initializeBackgroundServices();
  }

  static Future<void> _initializeBackgroundServices() async {
    try {
      await ensureFirebaseReady();
    } catch (error, stackTrace) {
      debugPrint('Huzur Firebase startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    try {
      await NotificationAndWidgetService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('Huzur notification startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await CommunityPushService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('Huzur community push startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
