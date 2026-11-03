import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/v42_models.dart';
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

  Future<void> scheduleExactPrayerAlarm({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String maqam,
    required int preReminderMinutes,
  }) async {
    await initialize();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final now = DateTime.now();

    if (!prayerTime.isAfter(now)) {
      return;
    }

    final safePreReminderMinutes = preReminderMinutes.clamp(0, 180).toInt();

    final reminderId = id + 10000;

    // Önce aynı hatırlatıcının eski kayıtları temizlenir.
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

    // 1. Önceden hatırlatma.
    if (safePreReminderMinutes > 0) {
      final reminderTime = prayerTime.subtract(
        Duration(minutes: safePreReminderMinutes),
      );

      if (reminderTime.isAfter(now)) {
        final reminderDate = tz.TZDateTime.from(
          reminderTime,
          tz.local,
        );

        await _notifications.zonedSchedule(
          id: reminderId,
          title: '$prayerName Vaktine Az Kaldı',
          body:
              '$prayerName vaktine $safePreReminderMinutes dakika kaldı. Hazırlanabilirsiniz.',
          scheduledDate: reminderDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }

    // 2. Namaz vaktinin tam zamanındaki bildirim.
    final prayerDate = tz.TZDateTime.from(
      prayerTime,
      tz.local,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: '$prayerName Vakti',
      body:
          '$prayerName vakti geldi. Huzurla ibadetinize vakit ayırın. Ezan makamı tercihiniz: $maqam.',
      scheduledDate: prayerDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

// ============================================================================
