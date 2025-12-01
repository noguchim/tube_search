import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static const String key = "favorite_videos";

  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  // ------------------------------------------------------------
  // 🔥 内部ロード関数
  // ------------------------------------------------------------
  Future<void> _load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    _cache = list.map((e) {
      try {
        return Map<String, dynamic>.from(json.decode(e));
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();

    _loaded = true;
  }

  // ------------------------------------------------------------
  // 🔥 外部公開（main.dart で await）
  // ------------------------------------------------------------
  Future<void> loadFavorites() async {
    await _load();
  }

  // ------------------------------------------------------------
  // 保存
  // ------------------------------------------------------------
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.map((v) => json.encode(v)).toList();
    await prefs.setStringList(key, list);
  }

  // ------------------------------------------------------------
  // 即時判定
  // ------------------------------------------------------------
  bool isFavoriteSync(String id) {
    return _cache.any((v) => v["id"] == id);
  }

  // ------------------------------------------------------------
  // ❤️ トグル（統合版）
  // ------------------------------------------------------------
  Future<void> toggle(String id, Map<String, dynamic> video) async {
    await _load();

    if (isFavoriteSync(id)) {
      _cache.removeWhere((v) => v["id"] == id);
    } else {
      final withDate = {
        ...video,
        "savedAt": DateTime.now().toString(),
      };
      _cache.add(withDate);
    }

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // お気に入り取得
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getFavorites() async {
    await _load();
    return List.from(_cache);
  }
}
