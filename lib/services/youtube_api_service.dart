// lib/services/youtube_api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tube_search/utils/app_logger.dart';

import '../models/youtube_video.dart';

class YouTubeApiService {
  YouTubeApiService();

  static const String baseApi = "nb-factory.jp";

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
    logger.i("🌐 API Request: $uri");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      logger.e("❌ API Error: ${res.statusCode} ${res.reasonPhrase}");
      throw Exception("API Error ${res.statusCode}");
    }

    logger.d("📥 Response: ${res.body}");
    return jsonDecode(res.body);
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
    final key = "search_${categoryId}_${kw.toLowerCase()}_$maxResults";

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
      );
    }).toList();
  }

// ------------------------------------------------------------
// サムネ選択系は PHP 側に任せるため Flutter では不要
// ------------------------------------------------------------
}
