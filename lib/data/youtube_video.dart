// lib/data/youtube_video.dart
import 'dart:math';

class YouTubeVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String? channelId;
  final String channelTitle;
  final DateTime? publishedAt;
  final int? viewCount;
  final int? durationSeconds;
  final bool isLive;
  final String? liveBroadcastContent;

  /// 検索ランキングスコア
  final double? score;

  final bool locked;
  final DateTime? savedAt;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.channelId,
    required this.channelTitle,
    this.publishedAt,
    this.viewCount,
    this.durationSeconds,
    this.isLive = false,
    this.liveBroadcastContent,
    this.score,
    this.locked = false,
    this.savedAt,
  });

  int get popularity {
    if (score == null) return 0;

    final s = score!;

    // 🔥 ガード
    if (s.isNaN || s.isInfinite || s <= 0) return 0;

    return (sqrt(s) * 100).round();
  }
}
