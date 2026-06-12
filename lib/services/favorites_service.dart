import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/youtube_video.dart';
import '../providers/iap_provider.dart';
import 'limit_service.dart';

class FavoritesService extends ChangeNotifier {
  static const String key = "favorite_videos";

  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  List<YouTubeVideo> get items => _cache.map((v) {
        return YouTubeVideo(
          id: v["id"] ?? "",
          title: v["title"] ?? "",
          thumbnailUrl: v["thumbnailUrl"] ?? "",
          channelId: v["channelId"]?.toString(),
          channelTitle: v["channelTitle"] ?? "",
          publishedAt: DateTime.tryParse(v["publishedAt"] ?? ""),
          viewCount: v["viewCount"],
          durationSeconds: v["durationSeconds"],
          savedAt: DateTime.tryParse(v["savedAt"] ?? ""),
          locked: v["locked"] == true,
        );
      }).toList();

  // ------------------------------------------------------------
  // 内部ロード
  // ------------------------------------------------------------
  Future<void> _load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    _cache = list
        .map((e) {
          try {
            final map = Map<String, dynamic>.from(json.decode(e));

            // 旧データ互換
            map["locked"] ??= false;

            return map;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    _loaded = true;
  }

  // ------------------------------------------------------------
  // 外部公開ロード
  // ------------------------------------------------------------
  Future<void> loadFavorites() async {
    await _load();
    notifyListeners();
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
      orElse: () => <String, dynamic>{},
    );
    return v["locked"] == true;
  }

  // ------------------------------------------------------------
  // トグル
  // ------------------------------------------------------------
  Future<void> toggle(String id, YouTubeVideo video) async {
    await _load();

    if (isFavoriteSync(id)) {
      _cache.removeWhere((v) => v["id"] == id);
    } else {
      final map = {
        "id": video.id,
        "title": video.title,
        "thumbnailUrl": video.thumbnailUrl,
        "channelId": video.channelId,
        "channelTitle": video.channelTitle,
        "publishedAt": video.publishedAt?.toIso8601String(),
        "viewCount": video.viewCount,
        "durationSeconds": video.durationSeconds,
        "savedAt": DateTime.now().toIso8601String(),
        "locked": false,
      };

      _cache.add(map);
    }

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // ロック切り替え
  // ------------------------------------------------------------
  Future<void> toggleLock(String id) async {
    await _load();

    for (final v in _cache) {
      if (v["id"] == id) {
        v["locked"] = !(v["locked"] == true);
        break;
      }
    }

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // 削除（ロック考慮）
  // ------------------------------------------------------------
  Future<bool> tryDelete(String id) async {
    await _load();

    final target = _cache.firstWhere(
      (v) => v["id"] == id,
      orElse: () => <String, dynamic>{},
    );

    if (target.isEmpty) return false;

    if (target["locked"] == true) {
      return false;
    }

    _cache.removeWhere((v) => v["id"] == id);
    await _save();
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------
  // 上限チェック付き追加
  // ------------------------------------------------------------
  Future<bool> tryAddFavorite(
    String id,
    YouTubeVideo video,
    IapProvider iap,
  ) async {
    await _load();

    if (isFavoriteSync(id)) return true;

    final max = LimitService.favoritesLimit(iap);

    if (_cache.length >= max) {
      return false;
    }

    final map = {
      "id": video.id,
      "title": video.title,
      "thumbnailUrl": video.thumbnailUrl,
      "channelId": video.channelId,
      "channelTitle": video.channelTitle,
      "publishedAt": video.publishedAt?.toIso8601String(),
      "viewCount": video.viewCount,
      "durationSeconds": video.durationSeconds,
      "savedAt": DateTime.now().toIso8601String(),
      "locked": false,
    };

    _cache.add(map);
    await _save();
    notifyListeners();

    return true;
  }

  // ------------------------------------------------------------
  // 取得
  // ------------------------------------------------------------
  Future<List<YouTubeVideo>> getFavorites() async {
    await _load();
    return items;
  }
}
