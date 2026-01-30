// lib/models/youtube_video.dart
class YouTubeVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime? publishedAt;
  final int? viewCount;
  final int? durationSeconds;
  final bool locked;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.publishedAt,
    this.viewCount,
    this.durationSeconds,
    this.locked = false,
  });
}
