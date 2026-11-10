import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/v42_models.dart';
import '../services/prayer_service.dart';
import '../data/hourly_verses.g.dart';

class NotificationAndWidgetService {
  static final NotificationAndWidgetService instance =
      NotificationAndWidgetService._();
  NotificationAndWidgetService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeChannel =
      MethodChannel('com.ilahi.tefekkur/native_bridge');
  bool _initialized = false;

  static const int _prayerNotificationIdBase = 260000;
  static const int _prayerReminderIdBase = 261000;
  static const String _prayerNotificationsEnabledKey =
      'huzur_prayer_notifications_enabled';

  Future<bool> arePrayerNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prayerNotificationsEnabledKey) ?? false;
  }

  Future<bool> enablePrayerNotifications({
    required List<PrayerNotificationTime> prayerTimes,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    final scheduled = await _schedulePrayerNotifications(
      prayerTimes: prayerTimes,
      maqam: maqam,
      preReminderMinutes: preReminderMinutes,
      requestPermission: true,
    );

    if (scheduled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prayerNotificationsEnabledKey, true);
    }

    return scheduled;
  }

  Future<bool> refreshPrayerNotifications({
    required List<PrayerNotificationTime> prayerTimes,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    if (!await arePrayerNotificationsEnabled()) return false;

    return _schedulePrayerNotifications(
      prayerTimes: prayerTimes,
      maqam: maqam,
      preReminderMinutes: preReminderMinutes,
      requestPermission: false,
    );
  }

  Future<void> disablePrayerNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerNotificationsEnabledKey, false);
    await _cancelManagedPrayerNotifications();
  }

  Future<void> _cancelManagedPrayerNotifications() async {
    // Önceki tek-vakitli hatırlatıcının kayıtlarını da temizle.
    await _notifications.cancel(id: 101);
    await _notifications.cancel(id: 10101);

    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      final isPrayerNotification =
          request.id >= _prayerNotificationIdBase &&
              request.id < _prayerNotificationIdBase + 100;
      final isPrayerReminder =
          request.id >= _prayerReminderIdBase &&
              request.id < _prayerReminderIdBase + 100;

      if (isPrayerNotification || isPrayerReminder) {
        await _notifications.cancel(id: request.id);
      }
    }
  }

  Future<bool> _schedulePrayerNotifications({
    required List<PrayerNotificationTime> prayerTimes,
    required String maqam,
    required int preReminderMinutes,
    required bool requestPermission,
  }) async {
    await initialize();

    if (requestPermission) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted != true) return false;
      } else {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted =
              await androidPlugin.requestNotificationsPermission();
          if (granted == false) return false;
        }
      }
    }

    final now = DateTime.now();
    final upcoming = prayerTimes
        .where((entry) => entry.time.isAfter(now))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (upcoming.isEmpty) return false;

    await _cancelManagedPrayerNotifications();

    const androidDetails = AndroidNotificationDetails(
      'huzur_prayer_alerts_v2',
      'Namaz Vakti Bildirimleri',
      channelDescription:
          'Yaklaşan namaz vakitleri için sesli hatırlatmalar.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentBanner: true,
      presentList: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final safeMinutes = preReminderMinutes.clamp(0, 180).toInt();
    var scheduledCount = 0;

    for (final entry in upcoming) {
      final slot = entry.dayOffset * 5 + entry.prayerIndex;
      final prayerId = _prayerNotificationIdBase + slot;
      final reminderId = _prayerReminderIdBase + slot;

      if (safeMinutes > 0) {
        final reminderTime =
            entry.time.subtract(Duration(minutes: safeMinutes));

        if (reminderTime.isAfter(now)) {
          await _notifications.zonedSchedule(
            id: reminderId,
            title: '${entry.prayerName} Vaktine Az Kaldı',
            body:
                '${entry.prayerName} vaktine $safeMinutes dakika kaldı. Hazırlığınızı yapabilirsiniz.',
            scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'prayer_reminder:${entry.prayerName}',
          );
          scheduledCount++;
        }
      }

      await _notifications.zonedSchedule(
        id: prayerId,
        title: '${entry.prayerName} Vakti',
        body:
            '${entry.prayerName} vakti geldi. Huzurla ibadetinize vakit ayırın.',
        scheduledDate: tz.TZDateTime.from(entry.time, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer_time:${entry.prayerName}',
      );
      scheduledCount++;
    }

    return scheduledCount > 0;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final deviceTimeZone =
          await _nativeChannel.invokeMethod<String>('getLocalTimeZone');

      if (deviceTimeZone != null && deviceTimeZone.trim().isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(deviceTimeZone));
      }
    } catch (_) {
      // Yerel saat dilimi sonraki native köprü adımında etkinleştirilecek.
    }
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false);
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    try {
      await _notifications.cancel(id: 777);
    } catch (_) {}

    final retiredSupportPrefs = await SharedPreferences.getInstance();
    for (final key in const [
      'huzur_support_session_id',
      'huzur_support_short_code',
      'huzur_support_user_name',
      'huzur_support_status',
      'huzur_support_privacy_consent',
      'huzur_support_messages',
      'huzur_fcm_token',
      'huzur_cached_fcm_push_token_v1',
      'huzur_push_permission_status_v1',
      'huzur_device_push_id',
      'huzur_apns_device_token',
    ]) {
      await retiredSupportPrefs.remove(key);
    }

    _initialized = true;
  }

  static String smartSplitTurkishSentence(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return clean;

    final sentences = clean.split(RegExp(r'(?<=[.!?])\s+'));

    // Kısa ve tamamlanmış bir cümle varsa onu koru.
    for (final sentence in sentences) {
      final words =
          sentence.trim().split(' ').where((word) => word.isNotEmpty).toList();

      if (words.length >= 3 && words.length <= 8) {
        return sentence.trim();
      }
    }

    // Uzun ayetlerde anlamlı ilk ifadeyi alıntı olarak göster.
    final clauses = clean.split(RegExp(r'[,;:]'));
    for (final clause in clauses) {
      final words =
          clause.trim().split(' ').where((word) => word.isNotEmpty).toList();

      if (words.length >= 3) {
        return '${words.take(8).join(' ')}…';
      }
    }

    final words = clean.split(' ').where((word) => word.isNotEmpty).toList();

    if (words.length <= 8) return clean;

    return '${words.take(8).join(' ')}…';
  }

  static String smartSplitArabic(String raw) {
    final words = raw.trim().split(RegExp(r'\s+'));

    if (words.length <= 6) return raw.trim();

    return '${words.take(6).join(' ')} …';
  }

  static const List<HourlyShortVerse> _widgetVerses = kHourlyWidgetShortVerses;

  static int _hourSeed(DateTime value) {
    final hourStart = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
    );
    return hourStart.millisecondsSinceEpoch ~/ 3600000;
  }

  HourlyShortVerse getActiveHourlyVerse({int offset = 0}) {
    const verses = _widgetVerses;
    final rawIndex = (_hourSeed(DateTime.now()) + offset) % verses.length;
    final index = rawIndex < 0 ? rawIndex + verses.length : rawIndex;
    return verses[index];
  }

  Future<HourlyShortVerse> fetchLiveSplitVerseFromApi({int offset = 0}) async {
    // Eski çağrılarla uyumluluk; artık internet isteği yapılmaz.
    return getActiveHourlyVerse(offset: offset);
  }

  Future<void> syncHourlyVerseToWidget({
    int manualOffset = 0,
    bool forceAuto = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hourly_verse_offset', manualOffset);

    final pinnedArabic = prefs.getString('v42_pinned_widget_arabic');
    final pinnedTurkish = prefs.getString('v42_pinned_widget_turkish');
    final pinnedReference = prefs.getString('v42_pinned_widget_reference');

    final usePinned = !forceAuto &&
        prefs.getString('v42_widget_source') == 'pinned' &&
        pinnedArabic != null &&
        pinnedArabic.trim().isNotEmpty &&
        pinnedTurkish != null &&
        pinnedTurkish.trim().isNotEmpty &&
        pinnedReference != null &&
        pinnedReference.trim().isNotEmpty;

    if (!usePinned) {
      await prefs.setString('v42_widget_source', 'auto');
    }

    final Map<String, Object> payload;

    if (usePinned) {
      payload = {
        'arabic': pinnedArabic,
        'translation': pinnedTurkish,
        'reference': pinnedReference,
        'badge': 'Seçili Ayet',
        'source': 'pinned',
        'offset': manualOffset,
      };
    } else {
      final verse = getActiveHourlyVerse(offset: manualOffset);
      payload = {
        'arabic': verse.arabicShort,
        'translation': verse.turkishShort,
        'reference': verse.reference,
        'badge': 'Günün İlhamı',
        'source': 'auto',
        'offset': manualOffset,
      };
    }

    try {
      await _nativeChannel.invokeMethod(
        'enableHourlyLockScreenVerse',
        payload,
      );
    } catch (_) {
      // Uygulama tekrar açıldığında senkronizasyon yeniden denenir.
    }
  }

  Future<bool> pinCustomVerseToWidget({
    required String arabic,
    required String turkish,
    required String reference,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final shortTr = smartSplitTurkishSentence(turkish);
    final shortAr = smartSplitArabic(arabic);

    await prefs.setString('v42_pinned_widget_arabic', shortAr);
    await prefs.setString('v42_pinned_widget_turkish', shortTr);
    await prefs.setString('v42_pinned_widget_reference', reference);
    await prefs.setString('v42_widget_source', 'pinned');

    final offset = prefs.getInt('hourly_verse_offset') ?? 0;

    try {
      await _nativeChannel.invokeMethod(
        'enableHourlyLockScreenVerse',
        {
          'arabic': shortAr,
          'translation': shortTr,
          'reference': reference,
          'badge': 'Seçili Ayet',
          'source': 'pinned',
          'offset': offset,
        },
      );
      return true;
    } catch (_) {
      // Sabit ayet tercihi saklanır; sonraki senkronizasyonda denenir.
      return false;
    }
  }

  Future<bool> scheduleExactPrayerAlarm({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (!prayerTime.isAfter(now)) return false;

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final permissionGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permissionGranted != true) return false;
    }

    final safePreReminderMinutes = preReminderMinutes.clamp(0, 180).toInt();
    final reminderId = id + 10000;

    await _notifications.cancel(id: id);
    await _notifications.cancel(id: reminderId);

    const androidDetails = AndroidNotificationDetails(
      'huzur_adhan_channel',
      'Huzur Ezan Vakitleri',
      importance: Importance.max,
      priority: Priority.max,
    );

    const iosDetails = DarwinNotificationDetails(
      presentBanner: true,
      presentList: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (safePreReminderMinutes > 0) {
      final reminderTime = prayerTime.subtract(
        Duration(minutes: safePreReminderMinutes),
      );

      if (reminderTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          id: reminderId,
          title: '$prayerName Vaktine Az Kaldı',
          body:
              '$prayerName vaktine $safePreReminderMinutes dakika kaldı. Hazırlanabilirsiniz.',
          scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }

    await _notifications.zonedSchedule(
      id: id,
      title: '$prayerName Vakti',
      body:
          '$prayerName vakti geldi. Huzurla ibadetinize vakit ayırın. Ezan makamı tercihiniz: $maqam.',
      scheduledDate: tz.TZDateTime.from(prayerTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    return true;
  }
}

// ============================================================================
