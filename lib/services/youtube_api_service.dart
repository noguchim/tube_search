// lib/services/youtube_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tube_search/utils/app_logger.dart';

import '../data/pickup_selectable_item.dart';
import '../data/trending_keyword.dart';
import '../data/youtube_video.dart';
import '../providers/recommendation_history_provider.dart';

class YouTubeApiService {
  YouTubeApiService();

  static const String baseApi = "nb-factory.jp";

  String? _jwtToken;
  DateTime? _tokenExpiresAt;

  // -------------------------
  // 人気動画キャッシュ
  // -------------------------
  final Map<String, List<YouTubeVideo>> _popularCache = {};
  final Map<String, DateTime> _popularCacheTime = {};
  static const Duration _popularCacheTTL = Duration(minutes: 10);

  final Map<String, List<YouTubeVideo>> _searchCache = {};
  final Map<String, DateTime> _searchFetchedAt = {};

  final Map<String, Map<String, dynamic>> _contentCache = {};
  final Map<String, DateTime> _contentCacheTime = {};

  String? _stringValue(
    Map<dynamic, dynamic> json,
    String camelKey,
    String snakeKey,
  ) {
    final value = json[camelKey] ?? json[snakeKey];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  // ------------------------------------------------------------
  // 🔧 GET JSON 共通処理
  // ------------------------------------------------------------
  Future<dynamic> _getJson(Uri uri, {int retryCount = 0}) async {
    await _ensureToken();

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
    );

    if (res.statusCode == 401) {
      if (retryCount >= 1) {
        throw Exception("API unauthorized after retry");
      }

      _jwtToken = null;
      return _getJson(uri, retryCount: retryCount + 1);
    }

    if (res.statusCode != 200) {
      throw Exception("API Error ${res.statusCode}");
    }

    return jsonDecode(res.body);
  }

  Future<void> _ensureToken() async {
    final now = DateTime.now();

    // まだ有効なら何もしない
    if (_jwtToken != null &&
        _tokenExpiresAt != null &&
        now.isBefore(_tokenExpiresAt!)) {
      return;
    }

    final uri = Uri.https(baseApi, "/api/auth.php");

    logger.i("🔐 Fetching API token...");
    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception("Token fetch failed");
    }

    final json = jsonDecode(res.body);
    _jwtToken = json["token"];
    final expiresIn = json["expires_in"] as int;

    // 少し余裕を持たせる（期限ギリギリ回避）
    _tokenExpiresAt = now.add(Duration(seconds: expiresIn - 30));

    logger.i("✅ API token ready (expires in ${expiresIn}s)");
  }

  Future<Map<String, dynamic>> fetchContentJson({
    required String type,
    String regionCode = "JP",
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final key = "${type}_$regionCode";

    if (!forceRefresh &&
        _contentCache.containsKey(key) &&
        _contentCacheTime.containsKey(key) &&
        now.difference(_contentCacheTime[key]!) < _popularCacheTTL) {
      return _contentCache[key]!;
    }

    final uri = Uri.https(baseApi, "/api/content_json.php", {
      "type": type,
      "region": regionCode,
    });

    final data = await _getJson(uri);

    if (data is! Map<String, dynamic>) {
      throw Exception("Invalid content API data");
    }

    _contentCache[key] = data;
    _contentCacheTime[key] = now;

    return data;
  }

  Map<String, dynamic>? getCachedContent({
    required String type,
    required String regionCode,
  }) {
    final key = "${type}_$regionCode";

    final cached = _contentCache[key];
    final time = _contentCacheTime[key];

    if (cached == null || time == null) return null;

    if (DateTime.now().difference(time) > _popularCacheTTL) {
      return null;
    }

    return cached;
  }

  // ============================================================
  // 1️⃣ 人気動画（PHP モジュールを経由）
  // ============================================================
  List<YouTubeVideo> getCachedPopular({
    required String regionCode,
    required int max,
  }) {
    final key = "$regionCode-$max";

    final cached = _popularCache[key];
    final time = _popularCacheTime[key];

    if (cached == null || time == null) return [];

    if (DateTime.now().difference(time) > _popularCacheTTL) {
      return [];
    }

    return cached;
  }

  Future<List<YouTubeVideo>> fetchPopularVideos({
    String regionCode = "JP",
    int hours = 12,
    int maxResults = 20,
    String? date, // ←追加
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final key = "${regionCode}_${hours}_${maxResults}_${date ?? 'now'}";

    // ------------------------------
    // cache
    // ------------------------------
    if (!forceRefresh &&
        _popularCache.containsKey(key) &&
        _popularCacheTime.containsKey(key) &&
        now.difference(_popularCacheTime[key]!) < _popularCacheTTL) {
      logger.i("💾 PopularVideos: Using cache ($key)");
      return _popularCache[key]!;
    }

    // ------------------------------
    // API
    // ------------------------------
    final uri = Uri.https(baseApi, "/api/youtube_popular_v3.php", {
      "region": regionCode,
      "max": "$maxResults",
    });

    final data = await _getJson(uri);

    if (data is! Map || data["items"] is! List) {
      logger.e("❌ Unexpected Popular API structure");
      throw Exception("Invalid API data");
    }

    final items = data["items"] as List;

    // ------------------------------
    // build model
    // ------------------------------
    final list = items.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? "")?.toLocal(),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
        score: (() {
          final vScore = (v["score"] as num?)?.toDouble();
          if (vScore == null) return null;
          if (vScore.isNaN || vScore.isInfinite) return null;
          return vScore;
        })(),
      );
    }).toList();

    list.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    // ------------------------------
    // cache save
    // ------------------------------
    _popularCache[key] = list;
    _popularCacheTime[key] = now;

    return list;
  }

  // ============================================================
  // 2️⃣ サジェスト（PHP モジュール）
  // ============================================================
  Future<List<String>> fetchSuggestions(
    String query, {
    String regionCode = "JP",
  }) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(baseApi, "/api/youtube_suggest.php", {
      "q": query,
      "region": regionCode,
    });

    final raw = await _getJson(uri);

    if (raw is List && raw.length >= 2 && raw[1] is List) {
      return (raw[1] as List).map((e) => e.toString()).toList();
    }

    logger.w("⚠️ Suggest unexpected structure");
    return [];
  }

  Future<List<YouTubeVideo>> searchWithStats({
    required String categoryId,
    required String keyword,
    required String searchMode,
    int maxResults = 50,
    String regionCode = "JP",
    bool forceRefresh = false,
  }) async {
    logger.i("💾 SearchWithStats: start");

    final kw = keyword.trim();
    if (kw.isEmpty) return [];

    final now = DateTime.now();

    final key =
        "search_${regionCode}_${categoryId}_${kw.toLowerCase()}_${searchMode}_$maxResults";

    logger.i("💾 SearchWithStats: key=$key");

    if (!forceRefresh &&
        _searchCache.containsKey(key) &&
        _searchFetchedAt.containsKey(key) &&
        now.difference(_searchFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 SearchWithStats: Using cache ($key)");
      return _searchCache[key]!;
    } else {
      logger.i("💾 SearchWithStats: No cache and search");
    }

    final params = {
      "q": kw,
      "mode": searchMode,
      "max": "$maxResults",
      "region": regionCode,
      "categoryId": categoryId, // ←追加（最重要）
    };

    logger.i(
        "[searchWithStats]query=$kw mode=$searchMode max=$maxResults region=$regionCode categoryId=$categoryId");

    final uri = Uri.https(
      baseApi,
      "/api/youtube_keyword_videos_v11.php",
      params,
    );

    final data = await _getJson(uri);

    if (data is! List) {
      logger.e("❌ Unexpected Keyword API structure");
      throw Exception("Invalid API data");
    }

    final list = data.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? "")?.toLocal(),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
        score: (() {
          final vScore = (v["score"] as num?)?.toDouble();
          if (vScore == null) return null;
          if (vScore.isNaN || vScore.isInfinite) return null;
          return vScore;
        })(),
      );
    }).toList();

    _searchCache[key] = list;
    _searchFetchedAt[key] = now;

    final listCount = list.length;
    logger.i("list-count=$listCount");
    return list;
  }

  // ============================================================
  // 5️⃣ 地域別トレンドキーワード（JWT + 新API仕様完全対応）
  // ============================================================
  Future<List<TrendingKeyword>> fetchTrendingKeywords({
    required String regionCode,
    bool forceRefresh = false,
  }) async {
    final data = await fetchContentJson(
      type: "trend",
      regionCode: regionCode,
      forceRefresh: forceRefresh,
    );

    final list = data["items"] as List;

    return list.map<TrendingKeyword>((v) {
      return TrendingKeyword(
        keyword: v["keyword"] ?? "",
        score: (v["score"] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<Map<String, List<YouTubeVideo>>> fetchPickupAll({
    String regionCode = "JP",
    bool forceRefresh = false,
  }) async {
    final data = await fetchContentJson(
      type: "pickup",
      regionCode: regionCode,
      forceRefresh: forceRefresh,
    );

    final items = data["items"] as Map<String, dynamic>;

    final result = <String, List<YouTubeVideo>>{};

    items.forEach((type, list) {
      final normalizedType = type == "all" ? "recommended" : type;
      final videos = (list as List).map<YouTubeVideo>((v) {
        return YouTubeVideo(
          id: v["id"] ?? "",
          title: v["title"] ?? "",
          thumbnailUrl: v["thumbnailUrl"] ?? "",
          channelId: _stringValue(v, "channelId", "channel_id"),
          channelTitle: v["channelTitle"] ?? "",
          publishedAt: DateTime.tryParse(v["publishedAt"] ?? "")?.toLocal(),
          viewCount: v["viewCount"] as int?,
          durationSeconds: v["durationSeconds"] as int?,
          score: (() {
            final vScore = (v["score"] as num?)?.toDouble();
            if (vScore == null) return null;
            if (vScore.isNaN || vScore.isInfinite) return null;
            return vScore;
          })(),
        );
      }).toList();

      videos.sort((a, b) {
        final aTime = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bTime.compareTo(aTime);
      });

      result[normalizedType] = videos;

      if (normalizedType == "recommended") {
        result["all"] = videos;
      }
    });

    return result;
  }

  Future<List<YouTubeVideo>> fetchRecommendedVideos({
    List<RecommendationSignal> signals = const [],
    Set<String> excludeChannelIds = const {},
    Set<String> excludeCategoryIds = const {},
    int maxResults = 5,
    String regionCode = "JP",
    bool forceRefresh = false,
  }) async {
    maxResults = maxResults.clamp(1, 50);

    final signalKey = signals
        .take(8)
        .map((signal) => '${signal.identity}:${signal.count}')
        .join('|');
    final excludeChannelKey = (excludeChannelIds.toList()..sort()).join(',');
    final excludeCategoryKey = (excludeCategoryIds.toList()..sort()).join(',');
    final key =
        "recommended_${regionCode}_${maxResults}_${signalKey}_exclude_${excludeChannelKey}_$excludeCategoryKey";
    final now = DateTime.now();

    if (!forceRefresh &&
        _searchCache.containsKey(key) &&
        _searchFetchedAt.containsKey(key) &&
        now.difference(_searchFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 RecommendedVideos: Using cache ($key)");
      return _searchCache[key]!;
    }

    final signalPayload = signals.take(8).map((signal) {
      return {
        "type": signal.type,
        "value": signal.value,
        "label": signal.label,
        "count": signal.count,
        "lastUsedAt": signal.lastUsedAt.toIso8601String(),
      };
    }).toList();

    final params = <String, String>{
      "region": regionCode,
      "max": "$maxResults",
    };

    if (signalPayload.isNotEmpty) {
      params["signals"] = jsonEncode(signalPayload);
    }
    if (excludeChannelIds.isNotEmpty) {
      params["exclude_channel_ids"] = excludeChannelIds.join(',');
    }
    if (excludeCategoryIds.isNotEmpty) {
      params["exclude_category_ids"] = excludeCategoryIds.join(',');
    }

    logger.i(
      "[fetchRecommendedVideos] "
      "signals=${signalPayload.length} region=$regionCode max=$maxResults "
      "excludeChannels=${excludeChannelIds.length} "
      "excludeCategories=${excludeCategoryIds.length}",
    );

    final uri = Uri.https(
      baseApi,
      "/api/youtube_recommended_videos.php",
      params,
    );

    final data = await _getJson(uri);
    final items = data is Map<String, dynamic> ? data["items"] : data;

    if (items is! List) {
      logger.e("❌ Unexpected RecommendedVideos API structure");
      throw Exception("Invalid RecommendedVideos API data");
    }

    final list = items.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? "")?.toLocal(),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
        score: (() {
          final vScore = (v["score"] as num?)?.toDouble();
          if (vScore == null) return null;
          if (vScore.isNaN || vScore.isInfinite) return null;
          return vScore;
        })(),
      );
    }).toList();

    list.sort((a, b) {
      final aScore = a.score ?? 0;
      final bScore = b.score ?? 0;

      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }

      final aTime = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    _searchCache[key] = list;
    _searchFetchedAt[key] = now;

    return list;
  }

  Future<void> saveFcmToken(
    String token,
    String regionCode,
    String deviceId, {
    int retryCount = 0,
  }) async {
    await _ensureToken();

    final uri = Uri.https(
      baseApi,
      "/api/save_fcm_token.php",
    );

    final info = await PackageInfo.fromPlatform();
    final appVersion = info.version;
    final locale = PlatformDispatcher.instance.locale;

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
      body: {
        'token': token,
        'device_id': deviceId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': appVersion,
        'locale': locale.languageCode,
        'region': regionCode,
      },
    );

    if (res.statusCode == 401) {
      logger.w("⚠️ JWT expired");

      if (retryCount >= 1) {
        logger.e("❌ saveFcmToken retry failed");

        throw Exception("JWT retry failed");
      }

      _jwtToken = null;

      return saveFcmToken(
        token,
        regionCode,
        deviceId,
        retryCount: retryCount + 1,
      );
    }

    if (res.statusCode != 200) {
      logger.e(
        "❌ saveFcmToken error: "
        "${res.statusCode} ${res.body}",
      );

      throw Exception("saveFcmToken failed");
    }

    logger.i("✅ FCM token saved");
  }

  Future<YouTubeVideo?> fetchVideoById(
    String videoId, {
    String regionCode = "JP",
    int retryCount = 0,
  }) async {
    logger.i("🎯 fetchVideoById: $videoId");

    if (videoId.trim().isEmpty) return null;

    int? parseIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    await _ensureToken();

    final uri = Uri.https(
      baseApi,
      "/api/get_video_by_id.php",
      {
        "videoId": videoId,
        "region": regionCode,
      },
    );

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
    );

    logger.i("🔥 RAW API RESPONSE:");
    logger.i(res.body);

    if (res.statusCode == 401) {
      if (retryCount >= 1) {
        logger.e("❌ fetchVideoById JWT retry failed");
        return null;
      }

      _jwtToken = null;

      return fetchVideoById(
        videoId,
        regionCode: regionCode,
        retryCount: retryCount + 1,
      );
    }

    if (res.statusCode != 200) {
      logger.e("❌ fetchVideoById error: ${res.statusCode} ${res.body}");
      return null;
    }

    final v = jsonDecode(res.body);

    if (v["error"] != null) {
      logger.w("⚠️ fetchVideoById: not found ($videoId)");
      return null;
    }

    try {
      final publishedAtRaw = v["publishedAt"]?.toString();

      return YouTubeVideo(
        id: v["id"]?.toString() ?? "",
        title: v["title"]?.toString() ?? "",
        thumbnailUrl: v["thumbnailUrl"]?.toString() ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channelTitle"]?.toString() ?? "",
        publishedAt: publishedAtRaw == null || publishedAtRaw.isEmpty
            ? null
            : DateTime.tryParse(publishedAtRaw)?.toLocal(),
        viewCount: parseIntOrNull(v["viewCount"]),
        durationSeconds: parseIntOrNull(v["durationSeconds"]),
        score: null,
      );
    } catch (e) {
      logger.e("❌ parse error fetchVideoById: $e");
      return null;
    }
  }

  Future<List<YouTubeVideo>> fetchRelatedVideos(
    String videoId, {
    int max = 4,
  }) async {
    final uri = Uri.https(
      baseApi,
      "/api/get_related_videos.php",
      {"videoId": videoId},
    );

    final data = await _getJson(uri);

    return (data as List).map((v) {
      return YouTubeVideo(
        id: v["video_id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnail_url"] ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channel_title"] ?? "",
        publishedAt: DateTime.tryParse(v["published_at"] ?? "")?.toLocal(),
        viewCount: int.tryParse("${v["view_count"]}"),
        durationSeconds: int.tryParse("${v["duration_seconds"]}"),
      );
    }).toList();
  }

  Future<void> replacePushSubscriptions({
    required String token,
    required List<PickupSelectableItem> items,
    bool resetSentLogs = false,
    int retryCount = 0,
  }) async {
    // if (items.isEmpty) {
    //   throw Exception("replacePushSubscriptions items is empty");
    // }

    await _ensureToken();

    final uri = Uri.https(
      baseApi,
      "/api/push_subscriptions_replace.php",
    );

    final payload = items.map((item) {
      return {
        'type': item.type.name,
        'title': item.title,
        'categoryId': item.categoryId,
        'channelId': item.channelId,
      };
    }).toList();

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
      body: {
        'token': token,
        'items': jsonEncode(payload),
        if (resetSentLogs) 'reset_sent_logs': '1',
      },
    );

    if (res.statusCode == 401) {
      logger.w("⚠️ JWT expired");

      if (retryCount >= 1) {
        logger.e("❌ replacePushSubscriptions retry failed");
        throw Exception("replacePushSubscriptions JWT retry failed");
      }

      _jwtToken = null;

      return replacePushSubscriptions(
        token: token,
        items: items,
        retryCount: retryCount + 1,
      );
    }

    if (res.statusCode != 200) {
      logger.e(
        "❌ replacePushSubscriptions error: "
        "${res.statusCode} ${res.body}",
      );

      throw Exception("replacePushSubscriptions failed");
    }

    logger.i(
      "✅ push subscriptions replaced count=${items.length}",
    );
  }

  Future<void> updatePushStatus({
    required String token,
    required bool enabled,
    int retryCount = 0,
  }) async {
    await _ensureToken();

    final uri = Uri.https(
      baseApi,
      "/api/push_status_update.php",
    );

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
      body: {
        'token': token,
        'status': enabled ? '1' : '0',
      },
    );

    if (res.statusCode == 401) {
      logger.w("⚠️ JWT expired");

      if (retryCount >= 1) {
        logger.e("❌ updatePushStatus retry failed");
        throw Exception("updatePushStatus JWT retry failed");
      }

      _jwtToken = null;

      return updatePushStatus(
        token: token,
        enabled: enabled,
        retryCount: retryCount + 1,
      );
    }

    if (res.statusCode != 200) {
      logger.e(
        "❌ updatePushStatus error: "
        "${res.statusCode} ${res.body}",
      );

      throw Exception("updatePushStatus failed");
    }

    logger.i("✅ push status updated [enabled=$enabled]");
  }

  Future<List<PickupSelectableItem>> fetchPickupChannels({
    String regionCode = "JP",
  }) async {
    final uri = Uri.https(
      baseApi,
      "/api/get_channels_master.php",
      {
        "region": regionCode,
      },
    );

    logger.i("[fetchPickupChannels] start uri=$uri");

    final data = await _getJson(uri);

    logger.i("[fetchPickupChannels] raw data=$data");

    if (data is! List) {
      logger.e("❌ Unexpected ChannelMaster API structure: $data");
      throw Exception("Invalid ChannelMaster API data");
    }

    return data.map<PickupSelectableItem>((v) {
      final json = Map<String, dynamic>.from(v as Map);

      return PickupSelectableItem.fromChannel(
        channelId: json["channel_id"]?.toString() ?? "",
        channelTitle: json["channel_title"]?.toString() ?? "",
        groupName: json["group_name"]?.toString(),
        categoryId: int.tryParse("${json["category_id"] ?? ""}"),
        region: json["region"]?.toString(),
        priority: int.tryParse("${json["priority"] ?? 0}") ?? 0,
      );
    }).where((item) {
      return item.channelId != null &&
          item.channelId!.isNotEmpty &&
          item.title.isNotEmpty;
    }).toList();
  }

  Future<List<YouTubeVideo>> fetchPickupTargetVideos({
    String? channelId,
    int? categoryId,
    int maxResults = 5,
    String regionCode = "JP",
    bool forceRefresh = false,
  }) async {
    final hasChannel = channelId != null && channelId.trim().isNotEmpty;
    final hasCategory = categoryId != null && categoryId > 0;

    if (!hasChannel && !hasCategory) {
      return [];
    }

    if (maxResults <= 0 || maxResults > 5) {
      maxResults = 5;
    }

    final normalizedChannelId = channelId?.trim() ?? "";
    final key =
        "pickup_target_${regionCode}_${normalizedChannelId}_${categoryId ?? 0}_$maxResults";

    final now = DateTime.now();

    if (!forceRefresh &&
        _searchCache.containsKey(key) &&
        _searchFetchedAt.containsKey(key) &&
        now.difference(_searchFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 PickupTargetVideos: Using cache ($key)");
      return _searchCache[key]!;
    }

    final params = <String, String>{
      "region": regionCode,
      "max": "$maxResults",
    };

    if (hasChannel) {
      params["channel_id"] = normalizedChannelId;
    } else {
      params["category_id"] = "${categoryId!}";
    }

    logger.i(
      "[fetchPickupTargetVideos] "
      "channelId=$normalizedChannelId categoryId=${categoryId ?? 0} "
      "region=$regionCode max=$maxResults",
    );

    final uri = Uri.https(
      baseApi,
      "/api/pickup_target_videos.php",
      params,
    );

    final data = await _getJson(uri);

    if (data is! List) {
      logger.e("❌ Unexpected PickupTargetVideos API structure");
      throw Exception("Invalid PickupTargetVideos API data");
    }

    final list = data.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelId: _stringValue(v, "channelId", "channel_id"),
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? "")?.toLocal(),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
        score: (() {
          final vScore = (v["score"] as num?)?.toDouble();
          if (vScore == null) return null;
          if (vScore.isNaN || vScore.isInfinite) return null;
          return vScore;
        })(),
      );
    }).toList();

    list.sort((a, b) {
      final aTime = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    _searchCache[key] = list;
    _searchFetchedAt[key] = now;

    logger.i("✅ PickupTargetVideos count=${list.length}");

    return list;
  }

  Future<Set<String>> fetchPushSubscriptionKeys({
    required String token,
  }) async {
    await _ensureToken();

    final uri = Uri.https(
      baseApi,
      "/api/push_subscriptions_get.php",
      {
        "token": token,
      },
    );

    final data = await _getJson(uri);

    if (data is! List) {
      throw Exception("Invalid push subscriptions data");
    }

    return data.map<String>((e) {
      final json = Map<String, dynamic>.from(e as Map);
      final type = json["subscription_type"]?.toString() ?? "";
      final value = json["subscription_value"]?.toString() ?? "";

      return "$type:$value";
    }).where((key) {
      return !key.endsWith(":");
    }).toSet();
  }

// ------------------------------------------------------------
// サムネ選択系は PHP 側に任せるため Flutter では不要
// ------------------------------------------------------------
}
