import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v42_models.dart';

String huzurIstanbulDayKey([DateTime? value]) {
  final instant =
      (value ?? DateTime.now()).toUtc().add(const Duration(hours: 3));

  final year = instant.year.toString().padLeft(4, "0");
  final month = instant.month.toString().padLeft(2, "0");
  final day = instant.day.toString().padLeft(2, "0");

  return "$year-$month-$day";
}

String huzurDailyDhikrStorageKey() {
  return "v42_daily_dhikr_${huzurIstanbulDayKey()}";
}

final userProgressProvider =
    StateNotifierProvider<UserProgressNotifier, UserProgressState>((ref) {
  return UserProgressNotifier();
});

class UserProgressNotifier extends StateNotifier<UserProgressState> {
  UserProgressNotifier() : super(const UserProgressState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSchema = prefs.getInt('v42_schema_version') ??
        UserProgressState.currentSchemaVersion;

    LastReadPosition? lastRead;
    final rawLastRead = prefs.getString('v42_last_read');
    if (rawLastRead != null && rawLastRead.isNotEmpty) {
      try {
        lastRead = LastReadPosition.fromJson(
            Map<String, dynamic>.from(jsonDecode(rawLastRead) as Map));
      } catch (_) {}
    }

    final List<SavedVerseRef> favs = [];
    final rawFavs = prefs.getStringList('v42_favorites') ?? const [];
    for (final item in rawFavs) {
      try {
        favs.add(SavedVerseRef.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map)));
      } catch (_) {}
    }

    final List<SavedVerseRef> bms = [];
    final rawBms = prefs.getStringList('v42_bookmarks') ?? const [];
    for (final item in rawBms) {
      try {
        bms.add(SavedVerseRef.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map)));
      } catch (_) {}
    }

    final legacyDailyDhikr = prefs.getInt("v42_daily_dhikr");
    if (legacyDailyDhikr != null &&
        !prefs.containsKey("v42_legacy_dhikr_total")) {
      await prefs.setInt("v42_legacy_dhikr_total", legacyDailyDhikr);
    }
    final dailyDhikr = prefs.getInt(huzurDailyDhikrStorageKey()) ?? 0;
    final missedPrayers = prefs.getInt('kaza_prayers') ?? 18;
    final initialPrayers = prefs.getInt('kaza_initial_prayers') ?? 60;
    final dailyPace = prefs.getInt('kaza_daily_pace') ?? 2;
    final missedFasts = prefs.getInt('kaza_fasts') ?? 4;

    final rawJuzs = prefs.getStringList('v42_completed_juzs') ?? const [];
    final completedJuzs = rawJuzs
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e >= 1 && e <= 30)
        .toSet();

    state = UserProgressState(
      schemaVersion: savedSchema,
      lastRead: lastRead,
      favorites: favs,
      bookmarks: bms,
      dailyDhikrCount: dailyDhikr,
      missedPrayers: missedPrayers,
      initialPrayers: initialPrayers,
      dailyPrayerPace: dailyPace,
      missedFasts: missedFasts,
      completedJuzs: completedJuzs,
    );
  }

  Future<void> saveLastRead(LastReadPosition pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v42_last_read', jsonEncode(pos.toJson()));
    state = state.copyWith(lastRead: pos);
  }

  Future<void> toggleFavorite(SavedVerseRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final exists = state.favorites.any((e) => e.key == ref.key);
    final updated = exists
        ? state.favorites.where((e) => e.key != ref.key).toList()
        : [ref, ...state.favorites];
    await prefs.setStringList(
      'v42_favorites',
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    state = state.copyWith(favorites: updated);
  }

  Future<void> toggleBookmark(SavedVerseRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final exists = state.bookmarks.any((e) => e.key == ref.key);
    final updated = exists
        ? state.bookmarks.where((e) => e.key != ref.key).toList()
        : [ref, ...state.bookmarks];
    await prefs.setStringList(
      'v42_bookmarks',
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    state = state.copyWith(bookmarks: updated);
  }

  Future<void> incrementDailyDhikr([int delta = 1]) async {
    if (delta == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final key = huzurDailyDhikrStorageKey();
    final current = prefs.getInt(key) ?? 0;
    final next = (current + delta).clamp(0, 9999999);

    await prefs.setInt(key, next);
    state = state.copyWith(dailyDhikrCount: next);
  }

  Future<void> updateKaza({
    int? missedPrayers,
    int? missedFasts,
    int? dailyPrayerPace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nextPrayers = (missedPrayers ?? state.missedPrayers).clamp(0, 99999);
    final nextFasts = (missedFasts ?? state.missedFasts).clamp(0, 9999);
    final nextPace = (dailyPrayerPace ?? state.dailyPrayerPace).clamp(1, 20);
    final nextInitial =
        nextPrayers > state.initialPrayers ? nextPrayers : state.initialPrayers;

    await prefs.setInt('kaza_initial_prayers', nextInitial);
    await prefs.setInt('kaza_prayers', nextPrayers);
    await prefs.setInt('kaza_fasts', nextFasts);
    await prefs.setInt('kaza_daily_pace', nextPace);

    state = state.copyWith(
      initialPrayers: nextInitial,
      missedPrayers: nextPrayers,
      missedFasts: nextFasts,
      dailyPrayerPace: nextPace,
    );
  }

  Future<void> toggleJuzCompleted(int juzNumber) async {
    if (juzNumber < 1 || juzNumber > 30) return;
    final prefs = await SharedPreferences.getInstance();
    final next = Set<int>.from(state.completedJuzs);
    if (next.contains(juzNumber)) {
      next.remove(juzNumber);
    } else {
      next.add(juzNumber);
    }
    await prefs.setStringList(
      'v42_completed_juzs',
      next.map((e) => e.toString()).toList(),
    );
    state = state.copyWith(completedJuzs: next);
  }

  Future<void> resetAllJuzProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('v42_completed_juzs');
    state = state.copyWith(completedJuzs: {});
  }
}
