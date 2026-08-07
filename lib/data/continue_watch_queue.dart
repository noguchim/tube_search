import 'youtube_video.dart';

enum ContinueWatchQueueStatus { ready, playing, paused, completed }

enum ContinueWatchItemStatus {
  pending,
  playing,
  paused,
  completed,
  skipped,
  excluded,
}

class ContinueWatchItem {
  final YouTubeVideo video;
  bool selected;
  ContinueWatchItemStatus status;
  int progressSeconds;

  ContinueWatchItem({
    required this.video,
    required this.selected,
    required this.status,
    this.progressSeconds = 0,
  });

  bool get eligible {
    final duration = video.durationSeconds ?? 0;
    final broadcast = video.liveBroadcastContent?.toLowerCase();
    return video.id.isNotEmpty &&
        duration > 0 &&
        !video.isLive &&
        broadcast != 'live' &&
        broadcast != 'upcoming';
  }

  double get progress {
    final duration = video.durationSeconds ?? 0;
    if (duration <= 0) return 0;
    return (progressSeconds / duration).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'video': _videoToJson(video),
    'selected': selected,
    'status': status.name,
    'progressSeconds': progressSeconds,
  };

  factory ContinueWatchItem.fromJson(Map<String, dynamic> json) {
    final video = _videoFromJson(
      Map<String, dynamic>.from(json['video'] as Map? ?? const {}),
    );
    final eligible = _isEligible(video);

    return ContinueWatchItem(
      video: video,
      selected: eligible && json['selected'] != false,
      status: eligible
          ? _itemStatusFromName(json['status']?.toString())
          : ContinueWatchItemStatus.excluded,
      progressSeconds: _asInt(json['progressSeconds']) ?? 0,
    );
  }
}

class ContinueWatchQueue {
  final String id;
  String title;
  final String sourceType;
  final String? sourceQuery;
  final DateTime createdAt;
  DateTime lastPlayedAt;
  ContinueWatchQueueStatus status;
  int currentIndex;
  bool pinned;
  final List<ContinueWatchItem> items;

  ContinueWatchQueue({
    required this.id,
    required this.title,
    required this.sourceType,
    this.sourceQuery,
    required this.createdAt,
    required this.lastPlayedAt,
    required this.status,
    required this.currentIndex,
    required this.pinned,
    required this.items,
  });

  int get selectedCount =>
      items.where((item) => item.selected && item.eligible).length;

  int get completedCount => items
      .where((item) => item.status == ContinueWatchItemStatus.completed)
      .length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sourceType': sourceType,
    'sourceQuery': sourceQuery,
    'createdAt': createdAt.toIso8601String(),
    'lastPlayedAt': lastPlayedAt.toIso8601String(),
    'status': status.name,
    'currentIndex': currentIndex,
    'pinned': pinned,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory ContinueWatchQueue.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map(
          (item) => ContinueWatchItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return ContinueWatchQueue(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceQuery: json['sourceQuery']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      lastPlayedAt:
          DateTime.tryParse(json['lastPlayedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: _queueStatusFromName(json['status']?.toString()),
      currentIndex: _asInt(json['currentIndex']) ?? 0,
      pinned: json['pinned'] == true,
      items: items,
    );
  }
}

bool _isEligible(YouTubeVideo video) {
  final duration = video.durationSeconds ?? 0;
  final broadcast = video.liveBroadcastContent?.toLowerCase();
  return video.id.isNotEmpty &&
      duration > 0 &&
      !video.isLive &&
      broadcast != 'live' &&
      broadcast != 'upcoming';
}

ContinueWatchQueueStatus _queueStatusFromName(String? name) {
  return ContinueWatchQueueStatus.values.firstWhere(
    (value) => value.name == name,
    orElse: () => ContinueWatchQueueStatus.ready,
  );
}

ContinueWatchItemStatus _itemStatusFromName(String? name) {
  return ContinueWatchItemStatus.values.firstWhere(
    (value) => value.name == name,
    orElse: () => ContinueWatchItemStatus.pending,
  );
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _videoToJson(YouTubeVideo video) => {
  'id': video.id,
  'title': video.title,
  'thumbnailUrl': video.thumbnailUrl,
  'channelId': video.channelId,
  'channelTitle': video.channelTitle,
  'publishedAt': video.publishedAt?.toIso8601String(),
  'viewCount': video.viewCount,
  'durationSeconds': video.durationSeconds,
  'isLive': video.isLive,
  'liveBroadcastContent': video.liveBroadcastContent,
  'score': video.score,
  'locked': video.locked,
  'savedAt': video.savedAt?.toIso8601String(),
};

YouTubeVideo _videoFromJson(Map<String, dynamic> json) => YouTubeVideo(
  id: json['id']?.toString() ?? '',
  title: json['title']?.toString() ?? '',
  thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
  channelId: json['channelId']?.toString(),
  channelTitle: json['channelTitle']?.toString() ?? '',
  publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
  viewCount: _asInt(json['viewCount']),
  durationSeconds: _asInt(json['durationSeconds']),
  isLive: json['isLive'] == true,
  liveBroadcastContent: json['liveBroadcastContent']?.toString(),
  score: json['score'] is num ? (json['score'] as num).toDouble() : null,
  locked: json['locked'] == true,
  savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? ''),
);
