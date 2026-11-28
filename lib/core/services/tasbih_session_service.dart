import "dart:async";
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import "dhikr_sync_service.dart";
import "prayer_service.dart";
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v42_models.dart';
import 'database_seeder.dart';
import 'user_progress_service.dart';

class TasbihSessionState {
  final List<TasbihRecord> records;
  final int activeIndex;
  final bool hapticEnabled;
  final int todayTotalCount;
  final bool isLoading;
  final String? loadError;

  const TasbihSessionState({
    this.records = const [],
    this.activeIndex = 0,
    this.hapticEnabled = true,
    this.todayTotalCount = 0,
    this.isLoading = true,
    this.loadError,
  });

  TasbihRecord? get activeRecord {
    if (records.isEmpty) return null;
    final idx = activeIndex.clamp(0, records.length - 1);
    return records[idx];
  }

  TasbihSessionState copyWith({
    List<TasbihRecord>? records,
    int? activeIndex,
    bool? hapticEnabled,
    int? todayTotalCount,
    bool? isLoading,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return TasbihSessionState(
      records: records ?? this.records,
      activeIndex: activeIndex ?? this.activeIndex,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      todayTotalCount: todayTotalCount ?? this.todayTotalCount,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : loadError ?? this.loadError,
    );
  }
}

final tasbihSessionProvider =
    StateNotifierProvider<TasbihSessionNotifier, TasbihSessionState>((ref) {
  return TasbihSessionNotifier(ref);
});

class TasbihSessionNotifier extends StateNotifier<TasbihSessionState> {
  final Ref _ref;
  late final DhikrSyncService _dhikrSyncService;
  Future<void> _persistenceTail = Future<void>.value();
  bool _loadingSession = false;

  TasbihSessionNotifier(this._ref) : super(const TasbihSessionState()) {
    _dhikrSyncService = DhikrSyncService();
    unawaited(loadSession());
  }

  String _pendingCountKey(int id) => 'huzur_tasbih_pending_count_$id';

  Future<void> loadSession() async {
    if (_loadingSession) return;
    _loadingSession = true;
    state = state.copyWith(isLoading: true, clearLoadError: true);

    try {
      final db = _ref.read(databaseServiceProvider);
      final prefs = await SharedPreferences.getInstance();
      var list = await db.getTasbihRecords();

      if (list.isEmpty) {
        await db.ensureDefaultTasbihRecords();
        list = await db.getTasbihRecords();
      }

      // Recover the newest local count if the app was closed while SQLite
      // persistence was pending. The backup is removed only after DB success.
      for (var index = 0; index < list.length; index++) {
        final record = list[index];
        final id = record.id;
        if (id == null) continue;
        final backupKey = _pendingCountKey(id);
        final pendingCount = prefs.getInt(backupKey);
        if (pendingCount == null) continue;

        if (pendingCount > record.count) {
          list[index] = record.copyWith(count: pendingCount);
          try {
            await db.updateTasbihCount(id, pendingCount);
            await prefs.remove(backupKey);
          } catch (error) {
            debugPrint('Huzur zikir yerel sayacı kurtarma beklemede: $error');
          }
        } else {
          await prefs.remove(backupKey);
        }
      }

      final haptic = prefs.getBool('v42_tasbih_haptic') ?? true;
      final savedIdx = prefs.getInt('v42_tasbih_active_idx') ?? 0;
      final dailyTotal = prefs.getInt(huzurDailyDhikrStorageKey()) ?? 0;

      if (!mounted) return;
      state = state.copyWith(
        records: list,
        activeIndex: list.isEmpty ? 0 : savedIdx.clamp(0, list.length - 1),
        hapticEnabled: haptic,
        todayTotalCount: dailyTotal,
        isLoading: false,
        clearLoadError: true,
      );
      unawaited(_dhikrSyncService.syncPending());
    } catch (error, stackTrace) {
      debugPrint('Huzur zikir kayıtları yüklenemedi: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          loadError: 'Zikir kayıtları yüklenemedi. Yeniden deneyebilirsin.',
        );
      }
    } finally {
      _loadingSession = false;
    }
  }

  Future<void> selectIndex(int index) async {
    if (index < 0 || index >= state.records.length) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('v42_tasbih_active_idx', index);
    state = state.copyWith(activeIndex: index);
  }

  Future<void> toggleHaptic(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('v42_tasbih_haptic', enabled);
    state = state.copyWith(hapticEnabled: enabled);
  }

  Future<int> incrementActive() {
    final current = state.activeRecord;
    if (current == null || state.isLoading) return Future<int>.value(0);

    final nextCount = current.count + 1;
    final updatedList = List<TasbihRecord>.from(state.records);
    final idx = state.activeIndex.clamp(0, updatedList.length - 1);
    updatedList[idx] = current.copyWith(count: nextCount);

    // Update the visible counter immediately; persistence is serialized below.
    state = state.copyWith(
      records: updatedList,
      todayTotalCount: state.todayTotalCount + 1,
    );

    final completer = Completer<int>();
    _persistenceTail = _persistenceTail.then((_) async {
      await _persistIncrement(current, nextCount);
      if (!completer.isCompleted) completer.complete(nextCount);
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('Huzur zikir kaydı kuyruğu: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!completer.isCompleted) completer.complete(nextCount);
    });
    return completer.future;
  }

  Future<void> _persistIncrement(TasbihRecord record, int nextCount) async {
    final id = record.id;
    if (id != null) {
      final backupKey = _pendingCountKey(id);
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
        await prefs.setInt(backupKey, nextCount);
      } catch (error) {
        debugPrint('Huzur zikir yedek sayacı yazılamadı: $error');
      }

      try {
        await _ref
            .read(databaseServiceProvider)
            .updateTasbihCount(id, nextCount);
        if (prefs != null) await prefs.remove(backupKey);
      } catch (error) {
        // Keep the SharedPreferences backup so the next launch can recover it.
        debugPrint('Huzur zikir SQLite kaydı beklemede: $error');
      }
    }

    try {
      await _ref.read(userProgressProvider.notifier).incrementDailyDhikr(1);
    } catch (error) {
      debugPrint('Huzur günlük zikir toplamı kaydedilemedi: $error');
    }

    try {
      final worldPrefs = await SharedPreferences.getInstance();
      final selectedCountryCode =
          worldPrefs.getString('huzur_world_country_code');
      await _dhikrSyncService.recordDhikr(
        countryName: selectedCountryCode ??
            _ref.read(prayerEngineProvider).selectedCity.country,
      );
    } catch (error) {
      debugPrint('Huzur Dünya zikir kuyruğu kaydedilemedi: $error');
    }
  }

  @override
  void dispose() {
    _dhikrSyncService.dispose();
    super.dispose();
  }

  Future<void> resetActiveCount() async {
    final current = state.activeRecord;
    if (current == null) return;

    final updatedList = List<TasbihRecord>.from(state.records);
    final idx = state.activeIndex.clamp(0, updatedList.length - 1);
    updatedList[idx] = current.copyWith(count: 0);
    state = state.copyWith(records: updatedList);

    // Reset is queued after prior taps so a pending increment cannot
    // overwrite the user's reset when its SQLite write completes later.
    final completer = Completer<void>();
    _persistenceTail = _persistenceTail.then((_) async {
      try {
        if (current.id != null) {
          await _ref
              .read(databaseServiceProvider)
              .updateTasbihCount(current.id!, 0);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_pendingCountKey(current.id!));
        }
      } catch (error, stackTrace) {
        debugPrint('Huzur zikir sıfırlama kaydı beklemede: $error');
        debugPrintStack(stackTrace: stackTrace);
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('Huzur zikir sıfırlama kuyruğu: $error');
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  Future<void> startEsmaTarget(EsmaulHusnaItem esma) async {
    final db = _ref.read(databaseServiceProvider);
    final title = "Yâ ${esma.transliteration}";
    final existingIdx = state.records
        .indexWhere((r) => r.title == title && r.target == esma.dhikrCount);

    if (existingIdx != -1) {
      await selectIndex(existingIdx);
      return;
    }

    await db.addCustomTasbih(title, esma.arabic, esma.dhikrCount);
    final refreshed = await db.getTasbihRecords();
    final newIdx = refreshed.length - 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('v42_tasbih_active_idx', newIdx);

    state = state.copyWith(
      records: refreshed,
      activeIndex: newIdx,
    );
  }

  Future<void> addCustomDhikr({
    required String title,
    required String arabic,
    required int target,
  }) async {
    final db = _ref.read(databaseServiceProvider);
    await db.addCustomTasbih(title, arabic, target);
    final refreshed = await db.getTasbihRecords();
    final newIdx = refreshed.length - 1;
    state = state.copyWith(
      records: refreshed,
      activeIndex: newIdx,
    );
  }
}
