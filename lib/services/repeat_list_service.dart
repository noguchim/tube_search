import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RepeatListService {
  static const _key = "repeat_lists";

  /// 🔹 1件の型
  /// {
  ///   "name": "...",
  ///   "queue": [ {...}, {...} ]
  /// }
  static Future<List<Map<String, dynamic>>> getLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      // 壊れていたら初期化
      return [];
    }
  }

  static Future<void> addDetailedList({
    required String name,
    required int startNo,
    required int endNo,
    required String sortMode,
    required List<Map<String, dynamic>> allVideos,
    required List<Map<String, dynamic>> queue,
    required bool useFullRange,
  }) async {
    final lists = await getLists();

    lists.add({
      "id": DateTime.now().microsecondsSinceEpoch.toString(),
      "name": name,
      "startNo": startNo, // ⭐ No を保存
      "endNo": endNo, // ⭐
      "sortMode": sortMode,
      "allVideos": allVideos,
      "queue": queue,
      "createdAt": DateTime.now().toIso8601String(),
      "useFullRange": useFullRange,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
  }

  /// 🔹 削除（index 指定）
  static Future<void> deleteAt(int index) async {
    final lists = await getLists();
    if (index < 0 || index >= lists.length) return;

    lists.removeAt(index);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
  }

  static Future<void> deleteById(String id) async {
    final lists = await getLists();
    lists.removeWhere((e) => e["id"] == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
  }

  /// 🔹 すべて削除
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> updateById(
    String id,
    Map<String, dynamic> newItem,
  ) async {
    final lists = await getLists();

    final index = lists.indexWhere((e) => e["id"] == id);
    if (index == -1) return;

    final old = lists[index];

    lists[index] = {
      ...old, // createdAt / id を維持
      ...newItem, // 値を更新
      "updatedAt": DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lists));
  }

  /// 🔹 List<dynamic> → List<Map<String,dynamic>>
  /// JSON往復で型が崩れても安全に復元する
  static List<Map<String, dynamic>> normalizeList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
