import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final huzurThemeModeProvider =
    StateNotifierProvider<HuzurThemeModeNotifier, ThemeMode>((ref) {
  return HuzurThemeModeNotifier();
});

class HuzurThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _storageKey = 'huzur_theme_mode_v1';

  HuzurThemeModeNotifier() : super(ThemeMode.system) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      for (final mode in ThemeMode.values) {
        if (mode.name == saved) {
          state = mode;
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }
}
