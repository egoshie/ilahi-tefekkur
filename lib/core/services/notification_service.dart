import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_models.dart';
import 'database_seeder.dart';

class NotificationAndWidgetService {
  static final NotificationAndWidgetService instance =
      NotificationAndWidgetService._();
  NotificationAndWidgetService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeChannel =
      MethodChannel('com.ilahi.tefekkur/native_bridge');

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  HourlyShortVerse getActiveHourlyVerse({int offset = 0}) {
    final now = DateTime.now();
    final hourSeed = now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;
    final list = DatabaseService.kHourlyShortVerses;
    return list[hourSeed.abs() % list.length];
  }

  Future<void> setHourlyLockScreenEnabled({
    required bool enabled,
    int manualOffset = 0,
  }) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hourly_lock_screen_enabled', enabled);
    await prefs.setInt('hourly_verse_offset', manualOffset);

    if (!enabled) {
      await _notifications.cancel(777);
      try {
        await _nativeChannel.invokeMethod('stopHourlyLockScreenVerse');
      } catch (_) {}
      return;
    }

    final verse = getActiveHourlyVerse(offset: manualOffset);

    // iOS & Android Kilit Ekranı Kartı
    final androidDetails = AndroidNotificationDetails(
      'lock_screen_hourly_short_verse',
      'Kilit Ekranı Saatlik Kısa Ayet Kartı',
      channelDescription: 'Kilit ekranında her saat başı değişen kısa Kuran ayeti kartı',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      showWhen: false,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        '${verse.arabicShort}\n"${verse.turkishShort}"',
        contentTitle: 'Kilit Ekranı Saatlik Ayet • ${verse.reference}',
        summaryText: verse.reference,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.active,
    );

    await _notifications.show(
      777,
      '${verse.turkishShort} (${verse.reference})',
      verse.arabicShort,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );

    // Native Köprü (iOS WidgetKit UserDefaults & Android LockScreen Overlay)
    try {
      await _nativeChannel.invokeMethod('enableHourlyLockScreenVerse', {
        'arabic': verse.arabicShort,
        'translation': verse.turkishShort,
        'reference': verse.reference,
        'badge': 'SAATLİK KISA AYET',
      });
    } catch (_) {}
  }

  Future<void> scheduleExactPrayerAlarm({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    await initialize();
    final now = DateTime.now();

    if (prayerTime.isAfter(now)) {
      try {
        await _nativeChannel.invokeMethod('scheduleExactAdhan', {
          'id': id,
          'prayerName': prayerName,
          'triggerAtMillis': prayerTime.millisecondsSinceEpoch,
          'maqam': maqam,
        });
      } catch (_) {}

      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      const androidDetails = AndroidNotificationDetails(
        'exact_adhan_channel_v3',
        'Sıfır Sapma Ezan Vakitleri',
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _notifications.zonedSchedule(
        id,
        '$prayerName Vakti Girdi',
        '$maqam ile vakit çağrısı • Huzurla eda ediniz.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
