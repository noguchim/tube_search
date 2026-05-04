// lib/services/youtube_api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tube_search/utils/app_logger.dart';

import '../data/trending_keyword.dart';
import '../data/youtube_video.dart';

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

  // ------------------------------------------------------------
  // 🔧 GET JSON 共通処理
  // ------------------------------------------------------------
  Future<dynamic> _getJson(Uri uri) async {
    await _ensureToken(); // ← これを追加

    logger.i("🌐 API Request: $uri");

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'User-Agent': 'NBFactoryApp/1.0',
      },
    );

    if (res.statusCode == 401) {
      // トークン失効時の自動リトライ（1回だけ）
      logger.w("🔁 Token expired, retrying...");
      _jwtToken = null;
      return _getJson(uri);
    }

    if (res.statusCode != 200) {
      logger.e("❌ API Error: ${res.statusCode} ${res.reasonPhrase}");
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
      "/api/youtube_keyword_videos_v10.php",
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
      final videos = (list as List).map<YouTubeVideo>((v) {
        return YouTubeVideo(
          id: v["id"] ?? "",
          title: v["title"] ?? "",
          thumbnailUrl: v["thumbnailUrl"] ?? "",
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

      videos.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

      result[type] = videos;
    });

    return result;
  }

// ------------------------------------------------------------
// サムネ選択系は PHP 側に任せるため Flutter では不要
// ------------------------------------------------------------
}
