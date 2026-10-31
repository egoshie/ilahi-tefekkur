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
  static final NotificationAndWidgetService instance = NotificationAndWidgetService._();
  NotificationAndWidgetService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeChannel = MethodChannel('com.ilahi.tefekkur/native_bridge');
  bool _initialized = false;
  HourlyShortVerse? _cachedLiveSplitVerse;
  int _lastFetchedHourSeed = -1;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _notifications.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
    try { await _notifications.cancel(777); } catch (_) {}
    _initialized = true;
  }

  static String smartSplitTurkishSentence(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 78) return clean;
    final parts = clean.split(RegExp(r'(?<=[.!?;:])\s+'));
    for (final p in parts) {
      final t = p.trim();
      if (t.length >= 16 && t.length <= 82) return t;
    }
    final clauses = clean.split(',');
    if (clauses.length >= 2) {
      final c = (clauses[0] + ',' + clauses).trim();
      if (c.length <= 82) return c + '.';
    }
    return clean.substring(0, 75).trim() + '...';
  }

  static String smartSplitArabic(String raw) {
    final words = raw.trim().split(RegExp(r'\s+'));
    if (words.length <= 7) return raw.trim();
    return words.take(6).join(' ');
  }

  HourlyShortVerse getActiveHourlyVerse({int offset = 0}) {
    final now = DateTime.now();
    final hourSeed = now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;
    if (_cachedLiveSplitVerse != null && _lastFetchedHourSeed == hourSeed) return _cachedLiveSplitVerse!;
    const list = OfflineSacredRepository.kHourlyShortVerses;
    return list[hourSeed.abs() % list.length];
  }

  Future<HourlyShortVerse> fetchLiveSplitVerseFromApi({int offset = 0}) async {
    final now = DateTime.now();
    final hourSeed = now.year * 8760 + now.month * 720 + now.day * 24 + now.hour + offset;
    if (offset == 0) return getActiveHourlyVerse(offset: 0);
    try {
      final ayahId = ((hourSeed * 37) % 6236) + 1;
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/\$ayahId/editions/quran-uthmani,tr.yazir')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List<dynamic>;
        final arObj = data[0] as Map<String, dynamic>;
        final trObj = data as Map<String, dynamic>;
        final surahNum = int.tryParse((arObj['surah'] as Map)['number'].toString()) ?? 1;
        final inSurah = int.tryParse(arObj['numberInSurah'].toString()) ?? 1;
        final sName = (surahNum >= 1 && surahNum <= 114) ? OfflineSacredRepository.kSurahNamesTr[surahNum - 1] : 'Sûre \$surahNum';
        final splitTr = smartSplitTurkishSentence((trObj['text'] ?? '').toString());
        final splitAr = smartSplitArabic((arObj['text'] ?? '').toString());
        final liveItem = HourlyShortVerse(index: offset, ayahKey: '\$surahNum:\$inSurah', arabicShort: splitAr, turkishShort: splitTr, reference: '\$sName, \$inSurah');
        _cachedLiveSplitVerse = liveItem;
        _lastFetchedHourSeed = hourSeed;
        return liveItem;
      }
    } catch (_) {}
    return getActiveHourlyVerse(offset: offset);
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
      });
    } catch (_) {}
  }

  Future<bool> pinCustomVerseToWidget({required String arabic, required String turkish, required String reference}) async {
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
      });
      return true;
    } catch (_) { return false; }
  }

  Future<void> scheduleExactPrayerAlarm({required int id, required String prayerName, required DateTime prayerTime, required String maqam, required int preReminderMinutes}) async {
    await initialize();
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    final now = DateTime.now();
    if (prayerTime.isAfter(now)) {
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      const androidDetails = AndroidNotificationDetails('huzur_adhan_channel', 'Huzur Ezan Vakitleri', importance: Importance.max, priority: Priority.max);
      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive);
      await _notifications.zonedSchedule(id, '\$prayerName Vakti', '\$maqam ile vakit çağrısı • Huzurla eda ediniz.', scheduledDate, const NotificationDetails(android: androidDetails, iOS: iosDetails), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    }
  }
}
