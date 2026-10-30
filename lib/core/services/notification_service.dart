import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/v42_models.dart';
import 'offline_sacred_repository.dart';

class NotificationAndWidgetService {
  static final NotificationAndWidgetService instance =
      NotificationAndWidgetService._();
  NotificationAndWidgetService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeChannel =
      MethodChannel('com.ilahi.tefekkur/native_bridge');

  bool _initialized = false;

  Future< void > initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);

    try {
      await _notifications.cancel(777);
    } catch (_) {}

    _initialized = true;
  }

  HourlyShortVerse getActiveHourlyVerse({int offset = 0}) {
    final now = DateTime.now();
    final hourSeed =
        now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;
    const list = OfflineSacredRepository.kHourlyShortVerses;
    return list[hourSeed.abs() % list.length];
  }

  Future< void > syncHourlyVerseToWidget({int manualOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hourly_verse_offset', manualOffset);

    final verse = getActiveHourlyVerse(offset: manualOffset);

    try {
      await _nativeChannel.invokeMethod('enableHourlyLockScreenVerse', {
        'arabic': verse.arabicShort,
        'translation': verse.turkishShort,
        'reference': verse.reference,
        'badge': 'Günün İlhamı',
      });
    } catch (_) {}
  }

  Future< bool > pinCustomVerseToWidget({
    required String arabic,
    required String turkish,
    required String reference,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v42_pinned_widget_arabic', arabic);
    await prefs.setString('v42_pinned_widget_turkish', turkish);
    await prefs.setString('v42_pinned_widget_reference', reference);

    try {
      await _nativeChannel.invokeMethod('enableHourlyLockScreenVerse', {
        'arabic': arabic,
        'translation': turkish,
        'reference': reference,
        'badge': 'Seçili Ayet',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future< void > scheduleExactPrayerAlarm({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    await initialize();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation< IOSFlutterLocalNotificationsPlugin >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final now = DateTime.now();
    if (prayerTime.isAfter(now)) {
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      const androidDetails = AndroidNotificationDetails(
        'huzur_adhan_channel',
        'Huzur Ezan Vakitleri',
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
        '$prayerName Vakti',
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
