import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/v42_models.dart';
import 'offline_sacred_repository.dart';

class NotificationAndWidgetService {
  NotificationAndWidgetService._();
  static final NotificationAndWidgetService instance = NotificationAndWidgetService._();

  static const MethodChannel _mediaChannel = MethodChannel('com.ilahi.tefekkur/media');
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  V42HourlyVerse getActiveHourlyVerse({int offset = 0}) {
    final items = OfflineSacredRepository.hourlyVerses;
    final index = (DateTime.now().hour + offset) % items.length;
    final item = items[index < 0 ? index + items.length : index];
    return item;
  }

  Future<void> syncHourlyVerseToWidget({int manualOffset = 0}) async {
    final verse = getActiveHourlyVerse(offset: manualOffset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hourly_verse_offset', manualOffset);
    await prefs.setString('huzur_widget_arabic', verse.arabicShort);
    await prefs.setString('huzur_widget_turkish', verse.turkishShort);
    await prefs.setString('huzur_widget_reference', verse.reference);
    try {
      await _mediaChannel.invokeMethod<void>('updateWidgetVerse', <String, String>{
        'arabic': verse.arabicShort,
        'turkish': verse.turkishShort,
        'reference': verse.reference,
      });
    } on MissingPluginException catch (e) {
      debugPrint('Widget köprüsü bulunamadı: $e');
    } on PlatformException catch (e) {
      debugPrint('Widget güncellenemedi: ${e.message}');
    }
  }

  Future<void> updateWidgetVerse({required String arabic, required String turkish, required String reference}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huzur_widget_arabic', arabic);
    await prefs.setString('huzur_widget_turkish', turkish);
    await prefs.setString('huzur_widget_reference', reference);
    try {
      await _mediaChannel.invokeMethod<void>('updateWidgetVerse', <String, String>{
        'arabic': arabic, 'turkish': turkish, 'reference': reference,
      });
    } on PlatformException catch (e) {
      debugPrint('Widget güncelleme isteği başarısız: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Widget native köprüsü yüklenmemiş: $e');
    }
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
    var remindAt = prayerTime.subtract(Duration(minutes: preReminderMinutes));
    if (!remindAt.isAfter(now)) remindAt = prayerTime;
    if (!remindAt.isAfter(now)) return;
    final localDate = tz.TZDateTime.from(remindAt, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'huzur_prayer_reminders', 'Namaz Vakti Hatırlatmaları',
        channelDescription: 'Namaz vakti ve öncesi hatırlatmaları',
        importance: Importance.max, priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _notifications.zonedSchedule(
      id, '$prayerName vakti yaklaşıyor',
      maqam.isEmpty ? 'Huzur vakit hatırlatıcısı' : '$maqam eşliğinde hazırlanabilirsiniz.',
      localDate, details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }
}

typedef NotificationService = NotificationAndWidgetService;
