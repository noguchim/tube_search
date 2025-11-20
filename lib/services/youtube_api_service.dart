// lib/services/youtube_api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YouTubeApiService {
  YouTubeApiService();

  static const String apiKey = 'AIzaSyCzTfcZnA6A_VSC11AQka-1_LaqNEdmgxI';

  static const _baseAuthority = 'www.googleapis.com';

  // ------------------------------
  // 内部共通 GET ＋ RAW ログ出力
  // ------------------------------
  Future<Map<String, dynamic>> _getJson(
      Uri uri, {
        bool debugRaw = false,
      }) async {
    if (debugRaw) {
      // 叩くURLを事前に出しておく
      // ignore: avoid_print
      print('🛰️ YouTube API Request: $uri');
    }

    final response = await http.get(uri);

    if (debugRaw) {
      // ignore: avoid_print
      print('📡 [${response.statusCode}] ${response.body}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'YouTube API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // =========================================================
  // 1️⃣ 人気動画取得（chart=mostPopular）
  // =========================================================
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

    final uri = Uri.https(
      _baseAuthority,
      '/youtube/v3/videos',
      queryParameters,
    );

    final json = await _getJson(uri, debugRaw: debugRaw);
    final items = (json['items'] as List<dynamic>? ?? []);

    // 🔥🔥 ここで items 件数を必ず出力（重要）🔥🔥
    print('🔥 fetchPopularVideos: API returned ${items.length} items');

    // もし追加で item の id も見たい場合
    // items.forEach((i) => print('id: ${(i as Map)['id']}'));

    return items
        .map((e) => _parseVideoFromVideosItem(e as Map<String, dynamic>))
        .toList();
  }

  // ----------------------------
  // 🔍 YouTube サジェスト取得
  // ----------------------------
  Future<List<String>> fetchSuggestions(String query) async {
    // 空なら空配列返す
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'suggestqueries.google.com',
      '/complete/search',
      {
        'client': 'firefox',
        'ds': 'yt',
        'q': query,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch suggestions: ${response.statusCode}',
      );
    }

    final raw = jsonDecode(response.body);

    // YouTube Suggest の構造:
    //   [ "keyword", ["候補1", "候補2", ...] ]
    if (raw is List && raw.length >= 2 && raw[1] is List) {
      return (raw[1] as List).map((e) => e.toString()).toList();
    }

    return [];
  }

  // =========================================================
  // 2️⃣ カテゴリ＋キーワード検索（Search APIのみ）
  //    ※ 以前の「複数API結果マージ」は一旦封印して安定化
  // =========================================================
  Future<List<YouTubeVideo>> searchVideosByCategoryAndKeyword(
      String categoryId,
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
        'videoCategoryId': categoryId,
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

  // =========================================================
  // 3️⃣ パース処理
  // =========================================================

  /// /videos?part=snippet,statistics の item 用
  YouTubeVideo _parseVideoFromVideosItem(Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    final snippet = item['snippet'] as Map<String, dynamic>?;

    // title, channelTitle, publishedAt が無い場合の補完
    final title = snippet?['title'] as String? ?? '(タイトルなし)';
    final channelTitle = snippet?['channelTitle'] as String? ?? '';
    final publishedAtStr = snippet?['publishedAt'] as String?;
    DateTime? publishedAt;
    if (publishedAtStr != null) {
      try {
        publishedAt = DateTime.parse(publishedAtStr);
      } catch (_) {}
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

  /// /search?part=snippet の item 用
  YouTubeVideo? _parseVideoFromSearchItem(Map<String, dynamic> item) {
    final idObj = item['id'] as Map<String, dynamic>?;
    final videoId = idObj?['videoId'] as String?;
    final snippet = item['snippet'] as Map<String, dynamic>?;

    if (videoId == null || snippet == null) return null;

    final title = snippet['title'] as String? ?? '';
    final channelTitle = snippet['channelTitle'] as String? ?? '';
    final publishedAtStr = snippet['publishedAt'] as String?;
    DateTime? publishedAt;
    if (publishedAtStr != null) {
      try {
        publishedAt = DateTime.parse(publishedAtStr);
      } catch (_) {}
    }

    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;

    final thumbnailUrl = _pickBestThumbnailUrl(thumbnails);

    return YouTubeVideo(
      id: videoId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      viewCount: null, // Search APIでは statistics が取れないので null
    );
  }

  /// サムネイルURLの一括ロジック
  String _pickBestThumbnailUrl(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return '';

    // あるものから順に使う
    const keys = ['maxres', 'standard', 'high', 'medium', 'default'];
    for (final key in keys) {
      final obj = thumbnails[key] as Map<String, dynamic>?;
      final url = obj?['url'] as String?;
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    return '';
  }
}
