import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
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
  HourlyShortVerse? _cachedLiveSplitVerse;
  int _lastFetchedHourSeed = -1;

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
    await _notifications.initialize(const InitializationSettings(
        android: androidSettings, iOS: iosSettings));
    try {
      await _notifications.cancel(777);
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

  HourlyShortVerse getActiveHourlyVerse({int offset = 0}) {
    final now = DateTime.now();
    final hourSeed =
        now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;
    if (_cachedLiveSplitVerse != null && _lastFetchedHourSeed == hourSeed)
      return _cachedLiveSplitVerse!;
    const list = OfflineSacredRepository.kHourlyShortVerses;
    return list[hourSeed.abs() % list.length];
  }

  Future<HourlyShortVerse> fetchLiveSplitVerseFromApi({int offset = 0}) async {
    final now = DateTime.now();
    final hourSeed =
        now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;

    if (_cachedLiveSplitVerse != null && _lastFetchedHourSeed == hourSeed) {
      return _cachedLiveSplitVerse!;
    }

    final fallback = getActiveHourlyVerse(offset: offset);

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.alquran.cloud/v1/ayah/random/editions/quran-uthmani,tr.yazir',
            ),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as List<dynamic>;

        if (data.length >= 2) {
          final arabic = data[0] as Map<String, dynamic>;
          final turkish = data[1] as Map<String, dynamic>;
          final surah = turkish['surah'] as Map<String, dynamic>;

          final surahNumber = int.tryParse(surah['number'].toString()) ?? 0;
          final ayahNumber =
              int.tryParse(turkish['numberInSurah'].toString()) ?? 0;

          final arabicText = (arabic['text'] ?? '').toString().trim();
          final turkishText = (turkish['text'] ?? '').toString().trim();

          if (surahNumber >= 1 &&
              surahNumber <= 114 &&
              ayahNumber > 0 &&
              arabicText.isNotEmpty &&
              turkishText.isNotEmpty) {
            final surahName =
                OfflineSacredRepository.kSurahNamesTr[surahNumber - 1];

            final verse = HourlyShortVerse(
              index: offset,
              ayahKey: '$surahNumber:$ayahNumber',
              arabicShort: smartSplitArabic(arabicText),
              turkishShort: smartSplitTurkishSentence(turkishText),
              reference: '$surahName, $ayahNumber',
            );

            _cachedLiveSplitVerse = verse;
            _lastFetchedHourSeed = hourSeed;
            return verse;
          }
        }
      }
    } catch (_) {
      // Ağ yoksa mevcut çevrimdışı ayet kullanılır.
    }

    _cachedLiveSplitVerse = fallback;
    _lastFetchedHourSeed = hourSeed;
    return fallback;
  }

  Future<void> syncHourlyVerseToWidget({int manualOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hourly_verse_offset', manualOffset);
    final verse = await fetchLiveSplitVerseFromApi(offset: manualOffset);
    try {
      await _nativeChannel.invokeMethod('enableHourlyLockScreenVerse', {
        'arabic': verse.arabicShort,
        'translation': verse.turkishShort,
        'reference': verse.reference,
        'badge': 'Günün İlhamı',
        'source': 'auto',
      });
    } catch (_) {}
  }

  Future<bool> pinCustomVerseToWidget(
      {required String arabic,
      required String turkish,
      required String reference}) async {
    final prefs = await SharedPreferences.getInstance();
    final shortTr = smartSplitTurkishSentence(turkish);
    final shortAr = smartSplitArabic(arabic);
    await prefs.setString('v42_pinned_widget_arabic', shortAr);
    await prefs.setString('v42_pinned_widget_turkish', shortTr);
    await prefs.setString('v42_pinned_widget_reference', reference);
    try {
      await _nativeChannel.invokeMethod('enableHourlyLockScreenVerse', {
        'arabic': shortAr,
        'translation': shortTr,
        'reference': reference,
        'badge': 'Seçili Ayet',
        'source': 'pinned',
      });
      return true;
    } catch (_) {
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
    await _notifications.cancel(id);
    await _notifications.cancel(reminderId);

    const androidDetails = AndroidNotificationDetails(
      'huzur_adhan_channel',
      'Huzur Ezan Vakitleri',
      importance: Importance.max,
      priority: Priority.max,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
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
          reminderId,
          '$prayerName Vaktine Az Kaldı',
          '$prayerName vaktine $safePreReminderMinutes dakika kaldı. Hazırlanabilirsiniz.',
          reminderDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // 2. Namaz vaktinin tam zamanındaki bildirim.
    final prayerDate = tz.TZDateTime.from(
      prayerTime,
      tz.local,
    );

    await _notifications.zonedSchedule(
      id,
      '$prayerName Vakti',
      '$prayerName vakti geldi. Huzurla ibadetinize vakit ayırın. Ezan makamı tercihiniz: $maqam.',
      prayerDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

// ============================================================================
