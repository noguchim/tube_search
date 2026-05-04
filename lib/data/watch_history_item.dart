import 'package:tube_search/data/youtube_video.dart';

class WatchHistoryItem {
  final YouTubeVideo video;
  final DateTime watchedAt;

  WatchHistoryItem({
    required this.video,
    required this.watchedAt,
  });

  factory WatchHistoryItem.fromVideo(YouTubeVideo v) {
    return WatchHistoryItem(
      video: v,
      watchedAt: DateTime.now(),
    );
  }
}
