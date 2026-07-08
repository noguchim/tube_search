import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/watch_history_item.dart';
import '../data/youtube_video.dart';

class WatchHistoryService extends ChangeNotifier {
  static const String key = "watch_history";
  static const int maxItems = 50;

  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  List<WatchHistoryItem> get items => _cache.map((v) {
        final video = YouTubeVideo(
          id: v["id"] ?? "",
          title: v["title"] ?? "",
          thumbnailUrl: v["thumbnailUrl"] ?? "",
          channelId: v["channelId"]?.toString(),
          channelTitle: v["channelTitle"] ?? "",
          publishedAt: DateTime.tryParse(v["publishedAt"] ?? ""),
          viewCount: v["viewCount"],
          durationSeconds: v["durationSeconds"],
          isLive: v["isLive"] == true,
          liveBroadcastContent: v["liveBroadcastContent"]?.toString(),
        );

        return WatchHistoryItem(
          video: video,
          watchedAt: DateTime.tryParse(v["watchedAt"] ?? "") ?? DateTime.now(),
        );
      }).toList();

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------
  Future<void> _load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    _cache = list
        .map((e) {
          try {
            return Map<String, dynamic>.from(json.decode(e));
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    // 🔥 追加：50件制限（古いの削除）
    if (_cache.length > maxItems) {
      _cache = _cache.sublist(0, 50);
    }

    _loaded = true;
  }

  Future<void> load() async {
    await _load();
    notifyListeners();
  }

  bool isWatchedSync(String id) {
    return _cache.any((v) => v["id"] == id);
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.map((v) => json.encode(v)).toList();
    await prefs.setStringList(key, list);
  }

  // ------------------------------------------------------------
  // ADD
  // ------------------------------------------------------------
  Future<void> add(YouTubeVideo video) async {
    await _load();

    // 重複削除（最新化）
    _cache.removeWhere((v) => v["id"] == video.id);

    final map = {
      "id": video.id,
      "title": video.title,
      "thumbnailUrl": video.thumbnailUrl,
      "channelId": video.channelId,
      "channelTitle": video.channelTitle,
      "publishedAt": video.publishedAt?.toIso8601String(),
      "viewCount": video.viewCount,
      "durationSeconds": video.durationSeconds,
      "isLive": video.isLive,
      "liveBroadcastContent": video.liveBroadcastContent,
      "watchedAt": DateTime.now().toIso8601String(),
    };

    _cache.insert(0, map);

    // 最大50件
    if (_cache.length > maxItems) {
      _cache.removeLast();
    }

    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _load();

    _cache.removeWhere((v) => v["id"] == id);

    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // CLEAR
  // ------------------------------------------------------------
  Future<void> clear() async {
    _cache.clear();
    await _save();
    notifyListeners();
  }
}
