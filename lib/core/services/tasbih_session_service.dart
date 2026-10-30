import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbihSession extends ChangeNotifier {
  TasbihSession._();
  static final TasbihSession instance = TasbihSession._();
  int count = 0;
  int target = 33;
  String label = 'Tesbih';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    count = prefs.getInt('tasbih_count') ?? 0;
    target = prefs.getInt('tasbih_target') ?? 33;
    label = prefs.getString('tasbih_label') ?? 'Tesbih';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTarget({required int value, required String name}) async {
    await load();
    target = value.clamp(1, 99999).toInt();
    label = name;
    count = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_target', target);
    await prefs.setString('tasbih_label', label);
    await prefs.setInt('tasbih_count', count);
    notifyListeners();
  }

  Future<void> increment() async {
    await load();
    count = count >= target ? 0 : count + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', count);
    notifyListeners();
  }

  Future<void> reset() async {
    count = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', 0);
    notifyListeners();
  }
}
