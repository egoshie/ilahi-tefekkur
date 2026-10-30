import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v42_models.dart';
import 'database_seeder.dart';
import 'user_progress_service.dart';

class TasbihSessionState {
  final List< TasbihRecord > records;
  final int activeIndex;
  final bool hapticEnabled;
  final int todayTotalCount;

  const TasbihSessionState({
    this.records = const [],
    this.activeIndex = 0,
    this.hapticEnabled = true,
    this.todayTotalCount = 0,
  });

  TasbihRecord? get activeRecord {
    if (records.isEmpty) return null;
    final idx = activeIndex.clamp(0, records.length - 1);
    return records[idx];
  }

  TasbihSessionState copyWith({
    List< TasbihRecord >? records,
    int? activeIndex,
    bool? hapticEnabled,
    int? todayTotalCount,
  }) {
    return TasbihSessionState(
      records: records ?? this.records,
      activeIndex: activeIndex ?? this.activeIndex,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      todayTotalCount: todayTotalCount ?? this.todayTotalCount,
    );
  }
}

final tasbihSessionProvider =
    StateNotifierProvider< TasbihSessionNotifier, TasbihSessionState >((ref) {
  return TasbihSessionNotifier(ref);
});

class TasbihSessionNotifier extends StateNotifier< TasbihSessionState > {
  final Ref _ref;

  TasbihSessionNotifier(this._ref) : super(const TasbihSessionState()) {
    loadSession();
  }

  Future< void > loadSession() async {
    final db = _ref.read(databaseServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final list = await db.getTasbihRecords();
    final haptic = prefs.getBool('v42_tasbih_haptic') ?? true;
    final savedIdx = prefs.getInt('v42_tasbih_active_idx') ?? 0;
    final dailyTotal = prefs.getInt('v42_daily_dhikr') ?? 0;

    state = state.copyWith(
      records: list,
      activeIndex: list.isEmpty ? 0 : savedIdx.clamp(0, list.length - 1),
      hapticEnabled: haptic,
      todayTotalCount: dailyTotal,
    );
  }

  Future< void > selectIndex(int index) async {
    if (index < 0 || index >= state.records.length) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('v42_tasbih_active_idx', index);
    state = state.copyWith(activeIndex: index);
  }

  Future< void > toggleHaptic(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('v42_tasbih_haptic', enabled);
    state = state.copyWith(hapticEnabled: enabled);
  }

  Future< int > incrementActive() async {
    final current = state.activeRecord;
    if (current == null) return 0;

    final nextCount = current.count + 1;
    final updatedList = List< TasbihRecord >.from(state.records);
    final idx = state.activeIndex.clamp(0, updatedList.length - 1);
    updatedList[idx] = current.copyWith(count: nextCount);

    state = state.copyWith(
      records: updatedList,
      todayTotalCount: state.todayTotalCount + 1,
    );

    if (current.id != null) {
      await _ref
          .read(databaseServiceProvider)
          .updateTasbihCount(current.id!, nextCount);
    }
    await _ref.read(userProgressProvider.notifier).incrementDailyDhikr(1);
    return nextCount;
  }

  Future< void > resetActiveCount() async {
    final current = state.activeRecord;
    if (current == null) return;

    final updatedList = List< TasbihRecord >.from(state.records);
    final idx = state.activeIndex.clamp(0, updatedList.length - 1);
    updatedList[idx] = current.copyWith(count: 0);
    state = state.copyWith(records: updatedList);

    if (current.id != null) {
      await _ref.read(databaseServiceProvider).updateTasbihCount(current.id!, 0);
    }
  }

  Future< void > startEsmaTarget(EsmaulHusnaItem esma) async {
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

  Future< void > addCustomDhikr({
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
