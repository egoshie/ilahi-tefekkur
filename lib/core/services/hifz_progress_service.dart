import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HifzVerseStatus { learning, memorized, needsReview }

class HifzProgressState {
  final Map<String, String> verseStatuses;
  final int dailyTarget;
  final int dailyRevisionCount;
  final String dailyDate;

  const HifzProgressState({
    this.verseStatuses = const {},
    this.dailyTarget = 5,
    this.dailyRevisionCount = 0,
    this.dailyDate = '',
  });

  String _key(int surah, int ayah) => '$surah:$ayah';

  HifzVerseStatus? statusFor(int surah, int ayah) {
    final value = verseStatuses[_key(surah, ayah)];
    for (final status in HifzVerseStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  bool isTracked(int surah, int ayah) =>
      verseStatuses.containsKey(_key(surah, ayah));

  int memorizedCountForSurah(int surah) => verseStatuses.entries
      .where((entry) =>
          entry.key.startsWith('$surah:') &&
          entry.value == HifzVerseStatus.memorized.name)
      .length;

  int get totalMemorized => verseStatuses.values
      .where((value) => value == HifzVerseStatus.memorized.name)
      .length;

  int get totalLearning => verseStatuses.values
      .where((value) => value == HifzVerseStatus.learning.name)
      .length;

  int get totalNeedsReview => verseStatuses.values
      .where((value) => value == HifzVerseStatus.needsReview.name)
      .length;

  HifzProgressState copyWith({
    Map<String, String>? verseStatuses,
    int? dailyTarget,
    int? dailyRevisionCount,
    String? dailyDate,
  }) {
    return HifzProgressState(
      verseStatuses: verseStatuses ?? this.verseStatuses,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      dailyRevisionCount: dailyRevisionCount ?? this.dailyRevisionCount,
      dailyDate: dailyDate ?? this.dailyDate,
    );
  }
}

final hifzProgressProvider =
    StateNotifierProvider<HifzProgressNotifier, HifzProgressState>((ref) {
  return HifzProgressNotifier();
});

class HifzProgressNotifier extends StateNotifier<HifzProgressState> {
  static const String _statusesKey = 'huzur_hifz_verse_statuses_v1';
  static const String _targetKey = 'huzur_hifz_daily_target_v1';
  static const String _revisionCountKey = 'huzur_hifz_revision_count_v1';
  static const String _revisionDateKey = 'huzur_hifz_revision_date_v1';

  HifzProgressNotifier() : super(const HifzProgressState()) {
    _restore();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statusesKey);
      final Map<String, String> statuses = {};

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.key is String &&
                entry.value is String &&
                HifzVerseStatus.values.any(
                  (status) => status.name == entry.value,
                )) {
              statuses[entry.key as String] = entry.value as String;
            }
          }
        }
      }

      final today = _todayKey();
      final savedDate = prefs.getString(_revisionDateKey) ?? today;
      final revisionCount =
          savedDate == today ? (prefs.getInt(_revisionCountKey) ?? 0) : 0;

      state = HifzProgressState(
        verseStatuses: statuses,
        dailyTarget: (prefs.getInt(_targetKey) ?? 5).clamp(1, 100),
        dailyRevisionCount: revisionCount,
        dailyDate: today,
      );

      if (savedDate != today) {
        await prefs.setString(_revisionDateKey, today);
        await prefs.setInt(_revisionCountKey, 0);
      }
    } catch (_) {}
  }

  Future<void> setVerseStatus(
    int surah,
    int ayah,
    HifzVerseStatus? status,
  ) async {
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) return;

    final next = Map<String, String>.from(state.verseStatuses);
    final key = '$surah:$ayah';

    if (status == null) {
      next.remove(key);
    } else {
      next[key] = status.name;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusesKey, jsonEncode(next));
    state = state.copyWith(verseStatuses: next);
  }

  Future<void> setDailyTarget(int target) async {
    final safeTarget = target.clamp(1, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, safeTarget);
    state = state.copyWith(dailyTarget: safeTarget);
  }

  Future<void> recordRevision() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final current = state.dailyDate == today ? state.dailyRevisionCount : 0;
    final next = current + 1;

    await prefs.setString(_revisionDateKey, today);
    await prefs.setInt(_revisionCountKey, next);

    state = state.copyWith(
      dailyRevisionCount: next,
      dailyDate: today,
    );
  }
}
