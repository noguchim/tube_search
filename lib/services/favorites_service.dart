import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/youtube_video.dart';
import '../providers/iap_provider.dart';
import 'limit_service.dart';
import 'youtube_api_service.dart';

class FavoritesService extends ChangeNotifier {
  static const String key = "favorite_videos";
  static const Duration _metadataRefreshCooldown = Duration(hours: 6);
  static const int _metadataVersion = 2;

  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;
  bool _isRefreshingMetadata = false;

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
      isLive: v["isLive"] == true,
      liveBroadcastContent: v["liveBroadcastContent"]?.toString(),
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
  // 未確定の動画時間・ライブ状態を再取得
  // ------------------------------------------------------------
  Future<void> refreshIncompleteMetadata(
    YouTubeApiService api, {
    String regionCode = "JP",
  }) async {
    await _load();
    if (_isRefreshingMetadata) return;

    final now = DateTime.now();
    final targetIds = _cache
        .where(_needsMetadataRefresh)
        .where((video) => _isMetadataRefreshDue(video, now))
        .map((video) => video["id"]?.toString() ?? "")
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (targetIds.isEmpty) return;

    _isRefreshingMetadata = true;
    var shouldSave = false;
    var metadataChanged = false;

    try {
      for (final videoId in targetIds) {
        YouTubeVideo? refreshed;
        try {
          refreshed = await api.fetchVideoById(videoId, regionCode: regionCode);
        } catch (error) {
          debugPrint(
            'Favorite metadata refresh failed: video=$videoId error=$error',
          );
          continue;
        }
        if (refreshed == null) continue;

        final index = _cache.indexWhere((video) => video["id"] == videoId);
        if (index < 0) continue;

        final current = _cache[index];
        final nextDuration = refreshed.durationSeconds;
        final nextIsLive = refreshed.isLive;
        final nextLiveContent = refreshed.liveBroadcastContent;
        final currentDuration = _parseDuration(current["durationSeconds"]);
        final hasLiveMetadata = nextLiveContent?.trim().isNotEmpty == true;
        final confirmsCompletedVideo = (nextDuration ?? 0) > 0;
        final canReplaceLiveMetadata =
            hasLiveMetadata || confirmsCompletedVideo;
        final mergedDuration = (nextDuration ?? 0) > 0
            ? nextDuration
            : currentDuration;
        final mergedIsLive = canReplaceLiveMetadata
            ? nextIsLive
            : current["isLive"] == true;
        final mergedLiveContent = canReplaceLiveMetadata
            ? nextLiveContent
            : current["liveBroadcastContent"]?.toString();

        metadataChanged =
            metadataChanged ||
            currentDuration != mergedDuration ||
            current["isLive"] != mergedIsLive ||
            current["liveBroadcastContent"] != mergedLiveContent;

        current["durationSeconds"] = mergedDuration;
        current["isLive"] = mergedIsLive;
        current["liveBroadcastContent"] = mergedLiveContent;
        current["metadataCheckedAt"] = DateTime.now().toIso8601String();
        current["metadataVersion"] = _metadataVersion;
        shouldSave = true;
      }

      if (shouldSave) {
        await _save();
      }
      if (metadataChanged) {
        notifyListeners();
      }
    } finally {
      _isRefreshingMetadata = false;
    }
  }

  bool _needsMetadataRefresh(Map<String, dynamic> video) {
    final duration = _parseDuration(video["durationSeconds"]);
    final liveContent = video["liveBroadcastContent"]
        ?.toString()
        .trim()
        .toLowerCase();

    return duration == null ||
        duration <= 0 ||
        video["isLive"] == true ||
        liveContent == "live" ||
        liveContent == "upcoming";
  }

  int? _parseDuration(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "");
  }

  bool _isMetadataRefreshDue(Map<String, dynamic> video, DateTime now) {
    if (video["metadataVersion"] != _metadataVersion) return true;

    final checkedAt = DateTime.tryParse(
      video["metadataCheckedAt"]?.toString() ?? "",
    );
    if (checkedAt == null) return true;

    return now.difference(checkedAt) >= _metadataRefreshCooldown;
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
        "isLive": video.isLive,
        "liveBroadcastContent": video.liveBroadcastContent,
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
      "isLive": video.isLive,
      "liveBroadcastContent": video.liveBroadcastContent,
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
