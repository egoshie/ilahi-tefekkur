import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyPlanTask {
  final String id;
  final String title;
  final String category;
  final bool completed;

  const DailyPlanTask({
    required this.id,
    required this.title,
    required this.category,
    this.completed = false,
  });

  DailyPlanTask copyWith({bool? completed}) {
    return DailyPlanTask(
      id: id,
      title: title,
      category: category,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'completed': completed,
      };

  factory DailyPlanTask.fromJson(Map<String, dynamic> json) {
    return DailyPlanTask(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'Kişisel').toString(),
      completed: json['completed'] == true,
    );
  }
}

class DailyPlanState {
  final String dayKey;
  final List<DailyPlanTask> tasks;
  final bool isLoading;

  const DailyPlanState({
    this.dayKey = '',
    this.tasks = const [],
    this.isLoading = true,
  });

  int get completedCount => tasks.where((task) => task.completed).length;

  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  DailyPlanState copyWith({
    String? dayKey,
    List<DailyPlanTask>? tasks,
    bool? isLoading,
  }) {
    return DailyPlanState(
      dayKey: dayKey ?? this.dayKey,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final dailyPlanProvider =
    StateNotifierProvider<DailyPlannerNotifier, DailyPlanState>((ref) {
  return DailyPlannerNotifier();
});

class DailyPlannerNotifier extends StateNotifier<DailyPlanState> {
  DailyPlannerNotifier() : super(const DailyPlanState()) {
    load();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static List<DailyPlanTask> _defaultTasks() => const [
        DailyPlanTask(
          id: 'default_quran',
          title: 'Kur’an tilaveti',
          category: 'Kur’an',
        ),
        DailyPlanTask(
          id: 'default_hifz',
          title: 'Hıfz tekrarı',
          category: 'Hıfz',
        ),
        DailyPlanTask(
          id: 'default_dhikr',
          title: 'Günlük zikir',
          category: 'Zikir',
        ),
        DailyPlanTask(
          id: 'default_reflection',
          title: 'Tefekkür ve dua',
          category: 'Tefekkür',
        ),
      ];

  String _storageKey(String dayKey) => 'huzur_daily_plan_$dayKey';

  Future<void> load() async {
    final dayKey = _todayKey();

    if (state.isLoading == false && state.dayKey == dayKey) {
      return;
    }

    state = DailyPlanState(dayKey: dayKey, isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(dayKey));

      List<DailyPlanTask> tasks;

      if (raw == null) {
        tasks = _defaultTasks();
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          tasks = decoded
              .whereType<Map>()
              .map((item) => DailyPlanTask.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((task) => task.id.isNotEmpty && task.title.isNotEmpty)
              .toList();
        } else {
          tasks = _defaultTasks();
        }
      }

      state = DailyPlanState(
        dayKey: dayKey,
        tasks: tasks,
        isLoading: false,
      );

      if (raw == null) {
        await _persist();
      }
    } catch (_) {
      state = DailyPlanState(
        dayKey: dayKey,
        tasks: _defaultTasks(),
        isLoading: false,
      );
    }
  }

  Future<void> refreshDay() async {
    if (state.dayKey != _todayKey()) {
      await load();
    }
  }

  Future<void> toggleTask(String id) async {
    final updated = state.tasks.map((task) {
      return task.id == id ? task.copyWith(completed: !task.completed) : task;
    }).toList();

    state = state.copyWith(tasks: updated);
    await _persist();
  }

  Future<void> addTask(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final task = DailyPlanTask(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      title: cleanTitle,
      category: 'Kişisel',
    );

    state = state.copyWith(tasks: [...state.tasks, task]);
    await _persist();
  }

  Future<void> removeTask(String id) async {
    state = state.copyWith(
      tasks: state.tasks.where((task) => task.id != id).toList(),
    );
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey(state.dayKey),
        jsonEncode(state.tasks.map((task) => task.toJson()).toList()),
      );
    } catch (_) {}
  }
}
