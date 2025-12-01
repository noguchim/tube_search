// lib/services/youtube_api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
//import '../utils/app_logger.dart';
import 'package:tube_search/utils/app_logger.dart';

import '../models/youtube_video.dart';

class YouTubeApiService {
  YouTubeApiService();

  static const String apiKey = 'AIzaSyCzTfcZnA6A_VSC11AQka-1_LaqNEdmgxI';
  static const _baseAuthority = 'www.googleapis.com';

  // ------------------------------------------------------------
  // 🔧 内部 GET 共通処理（logger 対応）
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    bool debugRaw = false,
  }) async {
    // 🔹 リクエストURL
    if (debugRaw) {
      logger.i('🛰️ [YouTube API Request] $uri');
    }

    final response = await http.get(uri);

    // 🔹 レスポンスRAW
    if (debugRaw) {
      logger.d('📡 [${response.statusCode}] ${response.body}');
    }

    if (response.statusCode != 200) {
      logger.e(
        '❌ YouTube API error: ${response.statusCode} ${response.reasonPhrase}',
      );
      throw Exception(
        'YouTube API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ============================================================
  // 1️⃣ 人気動画 (chart=mostPopular)
  // ============================================================
  Future<List<YouTubeVideo>> fetchPopularVideos({
    String regionCode = 'JP',
    int maxResults = 50,
    String? videoCategoryId,
    bool debugRaw = false,
  }) async {
    final queryParameters = <String, String>{
      'part': 'snippet,statistics',
      'chart': 'mostPopular',
      'regionCode': regionCode,
      'maxResults': '$maxResults',
      'key': apiKey,
    };

    if (videoCategoryId != null && videoCategoryId.isNotEmpty) {
      queryParameters['videoCategoryId'] = videoCategoryId;
    }

    final uri =
        Uri.https(_baseAuthority, '/youtube/v3/videos', queryParameters);

    logger.i('🔥 fetchPopularVideos() called '
        'category=$videoCategoryId region=$regionCode');

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    logger.i('📊 PopularVideos returned: ${items.length} items');

    return items
        .map((e) => _parseVideoFromVideosItem(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // 2️⃣ サジェスト取得
  // ============================================================
  Future<List<String>> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'suggestqueries.google.com',
      '/complete/search',
      {'client': 'firefox', 'ds': 'yt', 'q': query},
    );

    logger.d('🔍 fetchSuggestions("$query")');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      logger.e('❌ Suggest API error: ${response.statusCode}');
      throw Exception('Failed to fetch suggestions: ${response.statusCode}');
    }

    final raw = jsonDecode(response.body);

    if (raw is List && raw.length >= 2 && raw[1] is List) {
      final list = (raw[1] as List).map((e) => e.toString()).toList();
      logger.d('✨ Suggest hits: ${list.length} items');
      return list;
    }

    logger.w('⚠️ Unexpected suggest structure');
    return [];
  }

  // ============================================================
  // 3️⃣ カテゴリ + キーワード検索
  // ============================================================
  Future<List<YouTubeVideo>> searchVideosByCategoryAndKeyword(
    String categoryId,
    String keyword, {
    int maxResults = 50,
    String regionCode = 'JP',
    bool debugRaw = false,
  }) async {
    // 🔥 スペース対策
    keyword = keyword.trim();

    logger.i(
        '🔎 searchVideosByCategoryAndKeyword(cat:$categoryId, key:"$keyword")');

    final uri = Uri.https(
      _baseAuthority,
      '/youtube/v3/search',
      {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '$maxResults',
        'key': apiKey,
        'videoCategoryId': categoryId,
        'q': keyword,
        'regionCode': regionCode,
      },
    );

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    logger.i('📊 Search API returned: ${items.length} items');

    final result = items
        .map((e) => _parseVideoFromSearchItem(e as Map<String, dynamic>))
        .where((v) => v != null)
        .cast<YouTubeVideo>()
        .toList();

    logger.i('🎯 After filtering nulls: ${result.length} valid items');

    return result;
  }

  // =========================================================
  // 2.5️⃣ Search API + Videos API を統合して viewCount 付きで返す
  //      （独自カテゴリ用）
  // =========================================================
  Future<List<YouTubeVideo>> searchWithStats({
    required String categoryId,
    required String keyword,
    int maxResults = 50,
    String regionCode = 'JP',
    bool debugRaw = false,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      logger.w(
        'searchWithStats called with empty keyword. '
        'Falling back to fetchPopularVideos(categoryId=$categoryId)',
      );
      return fetchPopularVideos(
        regionCode: regionCode,
        maxResults: maxResults,
        videoCategoryId: categoryId,
        debugRaw: debugRaw,
      );
    }

    logger.i('🔎 searchWithStats(cat:$categoryId, key:"$trimmed")');

    // Step1: Search API で videoId の一覧を取る
    final searchResults = await searchVideosByCategoryAndKeyword(
      categoryId,
      trimmed,
      maxResults: maxResults,
      regionCode: regionCode,
      debugRaw: debugRaw,
    );

    if (searchResults.isEmpty) {
      logger.w('searchWithStats: Search API returned 0 items');
      return [];
    }

    // ID のみ取り出し
    final ids =
        searchResults.map((v) => v.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      logger.w('searchWithStats: no valid videoIds from search results');
      return [];
    }

    final idParam = ids.join(',');

    // Step2: Videos API で snippet + statistics をまとめて取る
    final uri = Uri.https(
      _baseAuthority,
      '/youtube/v3/videos',
      {
        'part': 'snippet,statistics',
        'id': idParam,
        'maxResults': '$maxResults',
        'key': apiKey,
      },
    );

    logger.i('🛰️ videos.list for stats: $uri');

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    logger.i(
      '📊 searchWithStats: videos API returned ${items.length} items '
      'for ${ids.length} requested ids',
    );

    final result = items
        .map((e) => _parseVideoFromVideosItem(e as Map<String, dynamic>))
        .toList();

    logger.i('🎯 searchWithStats: parsed ${result.length} items with stats');

    return result;
  }

  /// 🔥 動画IDをまとめて取得し statistics(viewCount) を得る
  Future<List<YouTubeVideo>> fetchVideosByIds(
    String videoIds, {
    bool debugRaw = false,
  }) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/videos',
      {
        'part': 'snippet,statistics',
        'id': videoIds,
        'key': apiKey,
        'maxResults': '50',
      },
    );

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    return items
        .map((e) => _parseVideoFromVideosItem(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<YouTubeVideo>> searchVideosByKeyword(
    String keyword, {
    int maxResults = 50,
    String regionCode = 'JP',
    bool debugRaw = false,
  }) async {
    final uri = Uri.https(
      _baseAuthority,
      '/youtube/v3/search',
      {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '$maxResults',
        'key': apiKey,
        'q': keyword,
        'regionCode': regionCode,
      },
    );

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    return items
        .map((e) => _parseVideoFromSearchItem(e as Map<String, dynamic>))
        .where((v) => v != null)
        .cast<YouTubeVideo>()
        .toList();
  }

  // ------------------------------------------------------------
  // パース処理
  // ------------------------------------------------------------

  YouTubeVideo _parseVideoFromVideosItem(Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    final snippet = item['snippet'] as Map<String, dynamic>?;

    final title = snippet?['title'] as String? ?? '(タイトルなし)';
    final channelTitle = snippet?['channelTitle'] as String? ?? '';
    final publishedAtStr = snippet?['publishedAt'] as String?;
    DateTime? publishedAt;

    if (publishedAtStr != null) {
      try {
        publishedAt = DateTime.parse(publishedAtStr);
      } catch (e) {
        logger.w('⚠️ Invalid publishedAt format: $publishedAtStr');
      }
    }

    final thumbnails = snippet?['thumbnails'] as Map<String, dynamic>?;
    final thumbnailUrl = _pickBestThumbnailUrl(thumbnails);

    final statistics = item['statistics'] as Map<String, dynamic>?;
    int? viewCount;

    if (statistics != null && statistics['viewCount'] != null) {
      viewCount = int.tryParse(statistics['viewCount'] as String);
    }

    return YouTubeVideo(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      viewCount: viewCount,
    );
  }

  YouTubeVideo? _parseVideoFromSearchItem(Map<String, dynamic> item) {
    final idMap = item['id'] as Map<String, dynamic>?;
    final snippet = item['snippet'] as Map<String, dynamic>?;

    final videoId = idMap?['videoId'] as String?;
    if (videoId == null || snippet == null) {
      logger.w('⚠️ Search item skipped (missing id/snippet)');
      return null;
    }

    final title = snippet['title'] as String? ?? '';
    final channelTitle = snippet['channelTitle'] as String? ?? '';
    final publishedAtStr = snippet['publishedAt'] as String?;
    DateTime? publishedAt;

    if (publishedAtStr != null) {
      try {
        publishedAt = DateTime.parse(publishedAtStr);
      } catch (e) {
        logger.w('⚠️ Invalid publishedAt format (search): $publishedAtStr');
      }
    }

    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
    final thumbnailUrl = _pickBestThumbnailUrl(thumbnails);

    return YouTubeVideo(
      id: videoId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      viewCount: null,
    );
  }

  // ------------------------------------------------------------
  // サムネ選択
  // ------------------------------------------------------------
  String _pickBestThumbnailUrl(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return '';

    const keys = ['maxres', 'standard', 'high', 'medium', 'default'];

    for (final key in keys) {
      final obj = thumbnails[key] as Map<String, dynamic>?;
      final url = obj?['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }

    logger.w('⚠️ No thumbnail found');
    return '';
  }
}
