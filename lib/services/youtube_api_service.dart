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
  final Map<String, DateTime> _popularFetchedAt = {};
  static const Duration _popularCacheTTL = Duration(minutes: 10);

  final Map<String, List<YouTubeVideo>> _searchCache = {};
  final Map<String, DateTime> _searchFetchedAt = {};

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

  // ============================================================
  // 1️⃣ 人気動画（PHP モジュールを経由）
  // ============================================================
  Future<List<YouTubeVideo>> fetchPopularVideos({
    String regionCode = "JP",
    int maxResults = 50,
    String? videoCategoryId,
    bool forceRefresh = false,
  }) async {
    logger.w(
        "🌐 fetchPopularVideos called region=$regionCode max=$maxResults force=$forceRefresh time=${DateTime.now()}");

    final now = DateTime.now();

    // 👇 maxResults & category をキャッシュキーに含める
    final key = "${regionCode}_${videoCategoryId ?? 'all'}_$maxResults";

    // キャッシュヒット
    if (!forceRefresh &&
        _popularCache.containsKey(key) &&
        _popularFetchedAt.containsKey(key) &&
        now.difference(_popularFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 PopularVideos: Using cache ($key)");
      return _popularCache[key]!;
    }

    // --- API 呼び出し ---
    final uri = Uri.https(baseApi, "/api/youtube_popular.php", {
      "region": regionCode,
      "max": "$maxResults",
      if (videoCategoryId != null && videoCategoryId.isNotEmpty)
        "category": videoCategoryId,
    });

    final data = await _getJson(uri);

    if (data is! List) {
      logger.e("❌ Unexpected Popular API structure");
      throw Exception("Invalid API data");
    }

    final list = data.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? ""),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
      );
    }).toList();

    // 👇 キーごとに保存
    _popularCache[key] = list;
    _popularFetchedAt[key] = now;

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

  // ============================================================
  // 3️⃣ キーワード検索 + 統計（PHP モジュール）
  // ============================================================
  Future<List<YouTubeVideo>> searchWithStats({
    required String categoryId,
    required String keyword,
    int maxResults = 50,
    String regionCode = "JP",
    bool forceRefresh = false, // ← ★ 追加
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return [];

    final now = DateTime.now();

    // 👇 キャッシュキー（kw を小文字に正規化）
    final key =
        "search_${regionCode}_${categoryId}_${kw.toLowerCase()}_$maxResults";

    // ------------------------
    // 💾 キャッシュヒット
    // ------------------------
    if (!forceRefresh &&
        _searchCache.containsKey(key) &&
        _searchFetchedAt.containsKey(key) &&
        now.difference(_searchFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 SearchWithStats: Using cache ($key)");
      return _searchCache[key]!;
    }

    // ------------------------
    // 🌐 API 呼び出し
    // ------------------------
    final uri = Uri.https(baseApi, "/api/youtube_search_with_stats.php", {
      "q": kw,
      "region": regionCode,
      "max": "$maxResults",
      if (categoryId.isNotEmpty) "category": categoryId,
    });

    final data = await _getJson(uri);

    if (data is! List) {
      logger.e("❌ Unexpected Search API structure");
      throw Exception("Invalid API data");
    }

    final list = data.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? ""),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
      );
    }).toList();

    // ------------------------
    // 💾 キャッシュ保存
    // ------------------------
    _searchCache[key] = list;
    _searchFetchedAt[key] = now;

    return list;
  }

  // ============================================================
  // 4️⃣ ID リスト詳細取得（PHP モジュール）
  // ============================================================
  Future<List<YouTubeVideo>> fetchVideosByIds(String ids) async {
    final uri = Uri.https(baseApi, "/api/youtube_videos.php", {
      "ids": ids,
    });

    final data = await _getJson(uri);

    if (data is! List) return [];

    return data.map<YouTubeVideo>((v) {
      return YouTubeVideo(
        id: v["id"] ?? "",
        title: v["title"] ?? "",
        thumbnailUrl: v["thumbnailUrl"] ?? "",
        channelTitle: v["channelTitle"] ?? "",
        publishedAt: DateTime.tryParse(v["publishedAt"] ?? ""),
        viewCount: v["viewCount"] as int?,
        durationSeconds: v["durationSeconds"] as int?,
      );
    }).toList();
  }

  // ============================================================
  // 5️⃣ 地域別トレンドキーワード（JWT + 新API仕様完全対応）
  // ============================================================
  final Map<String, List<TrendingKeyword>> _trendingCache = {};
  final Map<String, DateTime> _trendingFetchedAt = {};

  Future<List<TrendingKeyword>> fetchTrendingKeywords({
    required String regionCode, // 必須（多地域対応）
    int max = 10,
    bool forceRefresh = false,
  }) async {
    final region = regionCode.toUpperCase();
    final now = DateTime.now();

    logger.w(
        "🌐 fetchTrendingKeywords called region=$region max=$max force=$forceRefresh time=$now");

    // ★ popularと同思想のキャッシュキー（統一設計）
    final key = "${region}_$max";

    // ------------------------
    // 💾 キャッシュヒット（Popularと完全統一TTL）
    // ------------------------
    if (!forceRefresh &&
        _trendingCache.containsKey(key) &&
        _trendingFetchedAt.containsKey(key) &&
        now.difference(_trendingFetchedAt[key]!) < _popularCacheTTL) {
      logger.i("💾 TrendingKeywords: Using cache ($key)");
      return _trendingCache[key]!;
    }

    // ------------------------
    // 🌐 Trending API
    // /api/trending.php?region=JP&max=10&hours=12
    // ------------------------
    final uri = Uri.https(baseApi, "/api/trending.php", {
      "region": region,
      "max": "$max",
      "hours": "12", // ★ 半日サマリー（あなたの設計思想）
    });

    final data = await _getJson(uri);

    // ------------------------
    // 🧠 API構造チェック（堅牢化）
    // 期待:
    // {
    //   "keywords": [...],
    //   "generated_at": "ISO8601"
    // }
    // ------------------------
    if (data is! Map<String, dynamic>) {
      logger.w("⚠️ Trending API unexpected structure (not Map): $data");
      return [];
    }

    final rawKeywords = data["keywords"];
    final generatedAtStr = data["generated_at"];

    if (rawKeywords is! List) {
      logger.w("⚠️ Trending API missing keywords field: $data");
      return [];
    }

    // generated_at パース（失敗してもOK）
    DateTime? generatedAt;
    if (generatedAtStr is String) {
      generatedAt = DateTime.tryParse(generatedAtStr);
    }

    // ------------------------
    // 🎯 Model変換（Popularと同思想）
    // ------------------------
    final keywords = rawKeywords
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .map((keyword) => TrendingKeyword.fromApi(
              keyword: keyword,
              region: region,
              generatedAt: generatedAt,
            ))
        .toList(growable: false);

    // ------------------------
    // 💾 キャッシュ保存（統一設計）
    // ------------------------
    _trendingCache[key] = keywords;
    _trendingFetchedAt[key] = now;

    logger
        .i("🔥 Trending fetched: ${keywords.length} keywords (region=$region)");

    if (keywords.isEmpty) {
      logger.w("⚠️ Trending result is EMPTY (API/Batch/DB要確認)");
    }

    return keywords;
  }

  List<TrendingKeyword> getCachedTrending({
    required String regionCode,
    int max = 10,
  }) {
    final key = "${regionCode.toUpperCase()}_$max";
    return _trendingCache[key] ?? [];
  }

// ------------------------------------------------------------
// サムネ選択系は PHP 側に任せるため Flutter では不要
// ------------------------------------------------------------
}
