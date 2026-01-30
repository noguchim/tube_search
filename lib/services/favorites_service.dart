import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/iap_provider.dart';
import 'limit_service.dart';

class FavoritesService extends ChangeNotifier {
  static const String key = "favorite_videos";

  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  // ------------------------------------------------------------
  // 🔥 内部ロード
  // ------------------------------------------------------------
  Future<void> _load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    _cache = list.map((e) {
      try {
        final map = Map<String, dynamic>.from(json.decode(e));

        // ✅ 旧データ互換：locked が無ければ false
        map["locked"] ??= false;

        return map;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();

    _loaded = true;
  }

  // ------------------------------------------------------------
  // 🔥 外部公開ロード
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

  bool isLockedSync(String id) {
    final v = _cache.firstWhere(
      (e) => e["id"] == id,
      orElse: () => {},
    );
    return v["locked"] == true;
  }

  // ------------------------------------------------------------
  // ❤️ トグル（既存）
  // ------------------------------------------------------------
  Future<void> toggle(String id, Map<String, dynamic> video) async {
    await _load();

    if (isFavoriteSync(id)) {
      _cache.removeWhere((v) => v["id"] == id);
    } else {
      final withDate = {
        ...video,
        "savedAt": DateTime.now().toString(),
        "locked": false, // ← 初期は未ロック
      };
      _cache.add(withDate);
    }

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // 🔒 ロック切り替え（NEW）
  // ------------------------------------------------------------
  Future<void> toggleLock(String id) async {
    await _load();

    for (final v in _cache) {
      if (v["id"] == id) {
        v["locked"] = !(v["locked"] ?? false);
        break;
      }
    }

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // 🗑 削除（ロック考慮）
  // ------------------------------------------------------------
  Future<bool> tryDelete(String id) async {
    await _load();

    final target = _cache.firstWhere(
      (v) => v["id"] == id,
      orElse: () => {},
    );

    if (target.isEmpty) return false;

    // 🔒 ロック中は削除不可
    if (target["locked"] == true) {
      return false;
    }

    _cache.removeWhere((v) => v["id"] == id);
    await _save();
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------
  // ❤️ 上限チェック付き追加
  // ------------------------------------------------------------
  Future<bool> tryAddFavorite(
    String id,
    Map<String, dynamic> video,
    IapProvider iap,
  ) async {
    await _load();

    if (isFavoriteSync(id)) return true;

    final max = LimitService.favoritesLimit(iap);

    if (_cache.length >= max) {
      return false;
    }

    final withDate = {
      ...video,
      "savedAt": DateTime.now().toString(),
      "locked": false,
    };

    _cache.add(withDate);
    await _save();
    notifyListeners();

    return true;
  }

  // ------------------------------------------------------------
  // 取得（※ 並び替え拡張しやすい）
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getFavorites() async {
    await _load();

    // 🔒 ロック優先表示したい場合はここ
    // _cache.sort((a, b) {
    //   final la = a["locked"] == true;
    //   final lb = b["locked"] == true;
    //   if (la != lb) return la ? -1 : 1;
    //   return 0;
    // });

    return List.from(_cache);
  }
}
