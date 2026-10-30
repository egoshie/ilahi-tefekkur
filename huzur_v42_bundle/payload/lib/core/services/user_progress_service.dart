import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProgressService {
  UserProgressService._();
  static final UserProgressService instance = UserProgressService._();

  static const _bookmarkKey = 'huzur_v42_bookmarks';
  static const _lastPlaceKey = 'huzur_v42_last_place';

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_bookmarkKey) ?? const <String>[];
    return values.map((value) {
      try { return Map<String, dynamic>.from(jsonDecode(value) as Map); }
      catch (_) { return <String, dynamic>{}; }
    }).where((item) => item.isNotEmpty).toList();
  }

  Future<void> saveBookmark(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getBookmarks();
    final id = (item['id'] ?? '').toString();
    items.removeWhere((value) => value['id'] == id);
    items.insert(0, item);
    await prefs.setStringList(_bookmarkKey, items.map(jsonEncode).toList());
  }

  Future<void> removeBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getBookmarks();
    items.removeWhere((value) => value['id'] == id);
    await prefs.setStringList(_bookmarkKey, items.map(jsonEncode).toList());
  }

  Future<Map<String, dynamic>?> getLastPlace() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastPlaceKey);
    if (raw == null) return null;
    try { return Map<String, dynamic>.from(jsonDecode(raw) as Map); }
    catch (_) { return null; }
  }

  Future<void> saveLastPlace(Map<String, dynamic> place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlaceKey, jsonEncode(place));
  }

  Future<int> getHatimJuz() async => (await SharedPreferences.getInstance()).getInt('huzur_hatim_juz') ?? 0;
  Future<void> setHatimJuz(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('huzur_hatim_juz', value.clamp(0, 30).toInt());
  }
}
