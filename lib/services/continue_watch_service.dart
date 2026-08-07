import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/continue_watch_queue.dart';
import '../data/youtube_video.dart';

class ContinueWatchQueueLimitException implements Exception {
  final int limit;

  const ContinueWatchQueueLimitException(this.limit);
}

class ContinueWatchService extends ChangeNotifier {
  static const _storageKey = 'continue_watch_queues_v1';
  static const _activeQueueKey = 'continue_watch_active_queue_v1';
  static const freeQueueLimit = 10;
  static const proQueueLimit = 30;

  final List<ContinueWatchQueue> _queues = [];
  String? _activeQueueId;
  bool _loaded = false;
  bool _proEnabled;

  ContinueWatchService({bool proEnabled = false}) : _proEnabled = proEnabled;

  bool get loaded => _loaded;
  bool get proEnabled => _proEnabled;
  int get maxSavedQueues => _proEnabled ? proQueueLimit : freeQueueLimit;
  bool get canCreateQueue => _queues.length < maxSavedQueues;
  String? get activeQueueId => _activeQueueId;
  List<ContinueWatchQueue> get queues {
    final result = List<ContinueWatchQueue>.from(_queues);
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.lastPlayedAt.compareTo(a.lastPlayedAt);
    });
    return result;
  }

  ContinueWatchQueue? get activeQueue {
    final id = _activeQueueId;
    if (id == null) return null;
    return _findQueue(id);
  }

  bool get hasSavedQueues => _queues.isNotEmpty;

  ContinueWatchQueue? queueById(String id) => _findQueue(id);

  void setProEnabled(bool value) {
    _proEnabled = value;
  }

  int? nextPlayable(String queueId, int fromIndex) {
    final queue = _findQueue(queueId);
    if (queue == null) return null;
    return _findPlayable(queue, fromIndex + 1, forward: true);
  }

  static bool isEligibleVideo(YouTubeVideo video) {
    final duration = video.durationSeconds ?? 0;
    final broadcast = video.liveBroadcastContent?.toLowerCase();
    return video.id.isNotEmpty &&
        duration > 0 &&
        !video.isLive &&
        broadcast != 'live' &&
        broadcast != 'upcoming';
  }

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _activeQueueId = prefs.getString(_activeQueueKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        _queues
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map(
                  (item) => ContinueWatchQueue.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (queue) => queue.id.isNotEmpty && queue.items.isNotEmpty,
                ),
          );
        for (final queue in _queues) {
          if (queue.status == ContinueWatchQueueStatus.playing) {
            queue.status = ContinueWatchQueueStatus.paused;
            if (queue.currentIndex >= 0 &&
                queue.currentIndex < queue.items.length &&
                queue.items[queue.currentIndex].status ==
                    ContinueWatchItemStatus.playing) {
              queue.items[queue.currentIndex].status =
                  ContinueWatchItemStatus.paused;
            }
          }
        }
      } catch (error) {
        debugPrint('[ContinueWatchService] load failed: $error');
      }
    }

    if (_activeQueueId != null && _findQueue(_activeQueueId!) == null) {
      _activeQueueId = null;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<ContinueWatchQueue> createQueue({
    required String title,
    required String sourceType,
    String? sourceQuery,
    required List<YouTubeVideo> videos,
    Set<String>? selectedVideoIds,
  }) async {
    await load();
    if (!canCreateQueue) {
      throw ContinueWatchQueueLimitException(maxSavedQueues);
    }

    final seen = <String>{};
    final items = videos.where((video) => seen.add(video.id)).map((video) {
      final eligible = isEligibleVideo(video);
      return ContinueWatchItem(
        video: video,
        selected:
            eligible &&
            (selectedVideoIds == null || selectedVideoIds.contains(video.id)),
        status: eligible
            ? ContinueWatchItemStatus.pending
            : ContinueWatchItemStatus.excluded,
      );
    }).toList();

    final now = DateTime.now();
    final queue = ContinueWatchQueue(
      id: const Uuid().v4(),
      title: title,
      sourceType: sourceType,
      sourceQuery: sourceQuery,
      createdAt: now,
      lastPlayedAt: now,
      status: ContinueWatchQueueStatus.ready,
      currentIndex: _firstPlayableIndex(items),
      pinned: false,
      items: items,
    );

    _queues.add(queue);
    _activeQueueId = queue.id;
    await _save();
    notifyListeners();
    return queue;
  }

  Future<void> activate(String queueId) async {
    final queue = _findQueue(queueId);
    if (queue == null) return;
    _activeQueueId = queueId;
    queue.lastPlayedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> restart(String queueId) async {
    final queue = _findQueue(queueId);
    if (queue == null) return;
    _resetQueue(queue);
    _activeQueueId = queue.id;
    await _save();
    notifyListeners();
  }

  Future<void> toggleItem(String queueId, int index) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    final item = queue.items[index];
    if (!item.eligible) return;
    item.selected = !item.selected;
    await _save();
    notifyListeners();
  }

  Future<void> setAllItemsSelected(String queueId, bool selected) async {
    final queue = _findQueue(queueId);
    if (queue == null) return;
    for (final item in queue.items) {
      if (item.eligible) item.selected = selected;
    }
    await _save();
    notifyListeners();
  }

  Future<void> setCurrentIndex(String queueId, int index) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    if (!queue.items[index].selected || !queue.items[index].eligible) return;
    queue.currentIndex = index;
    queue.lastPlayedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<bool> prepareExplicitPlayback(
    String queueId,
    int index, {
    int restartThresholdSeconds = 5,
  }) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) {
      return false;
    }

    final item = queue.items[index];
    if (!item.selected || !item.eligible) return false;

    final restartingCompletedQueue =
        queue.status == ContinueWatchQueueStatus.completed;
    final duration = item.video.durationSeconds ?? 0;
    final remaining = duration - item.progressSeconds;
    final shouldRestart =
        restartingCompletedQueue ||
        item.status == ContinueWatchItemStatus.completed ||
        (item.progressSeconds > 0 && remaining <= restartThresholdSeconds);
    if (!shouldRestart) return false;

    if (restartingCompletedQueue) {
      for (var i = index; i < queue.items.length; i++) {
        final replayItem = queue.items[i];
        if (!replayItem.selected || !replayItem.eligible) continue;
        replayItem.progressSeconds = 0;
        replayItem.status = ContinueWatchItemStatus.pending;
      }
    } else {
      item.progressSeconds = 0;
      item.status = ContinueWatchItemStatus.pending;
    }
    queue.currentIndex = index;
    if (restartingCompletedQueue) {
      queue.status = ContinueWatchQueueStatus.ready;
    }
    queue.lastPlayedAt = DateTime.now();
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> markPlaying(String queueId, int index) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    queue.currentIndex = index;
    queue.status = ContinueWatchQueueStatus.playing;
    queue.lastPlayedAt = DateTime.now();
    queue.items[index].status = ContinueWatchItemStatus.playing;
    await _save();
    notifyListeners();
  }

  Future<void> markPaused(
    String queueId,
    int index, {
    required int progressSeconds,
  }) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    queue.status = ContinueWatchQueueStatus.paused;
    queue.currentIndex = index;
    queue.lastPlayedAt = DateTime.now();
    final item = queue.items[index];
    item.status = ContinueWatchItemStatus.paused;
    item.progressSeconds = _clampProgress(item, progressSeconds);
    await _save();
    notifyListeners();
  }

  Future<void> updateProgress(
    String queueId,
    int index,
    int progressSeconds,
  ) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    queue.items[index].progressSeconds = _clampProgress(
      queue.items[index],
      progressSeconds,
    );
    await _save();
    notifyListeners();
  }

  Future<int?> markCompletedAndFindNext(String queueId, int index) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return null;
    final item = queue.items[index];
    item.status = ContinueWatchItemStatus.completed;
    item.progressSeconds = item.video.durationSeconds ?? item.progressSeconds;

    final next = _findPlayable(queue, index + 1, forward: true);
    if (next == null) {
      queue.status = ContinueWatchQueueStatus.completed;
      queue.currentIndex = _firstPlayableIndex(queue.items);
    } else {
      queue.currentIndex = next;
      queue.status = ContinueWatchQueueStatus.ready;
    }
    queue.lastPlayedAt = DateTime.now();
    await _save();
    notifyListeners();
    return next;
  }

  Future<int?> skipAndFindNext(String queueId, int index) async {
    final queue = _findQueue(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return null;
    queue.items[index].status = ContinueWatchItemStatus.skipped;
    final next = _findPlayable(queue, index + 1, forward: true);
    if (next != null) queue.currentIndex = next;
    queue.status = next == null
        ? ContinueWatchQueueStatus.completed
        : ContinueWatchQueueStatus.ready;
    await _save();
    notifyListeners();
    return next;
  }

  int? previousPlayable(String queueId, int fromIndex) {
    final queue = _findQueue(queueId);
    if (queue == null) return null;
    return _findPlayable(queue, fromIndex - 1, forward: false);
  }

  Future<void> togglePinned(String queueId) async {
    final queue = _findQueue(queueId);
    if (queue == null) return;
    queue.pinned = !queue.pinned;
    await _save();
    notifyListeners();
  }

  Future<void> rename(String queueId, String title) async {
    final queue = _findQueue(queueId);
    final trimmed = title.trim();
    if (queue == null || trimmed.isEmpty) return;
    queue.title = trimmed;
    await _save();
    notifyListeners();
  }

  Future<void> delete(String queueId) async {
    _queues.removeWhere((queue) => queue.id == queueId);
    if (_activeQueueId == queueId) _activeQueueId = null;
    await _save();
    notifyListeners();
  }

  ContinueWatchQueue? _findQueue(String id) {
    for (final queue in _queues) {
      if (queue.id == id) return queue;
    }
    return null;
  }

  int _clampProgress(ContinueWatchItem item, int value) {
    final duration = item.video.durationSeconds ?? value;
    return value.clamp(0, duration).toInt();
  }

  int? _findPlayable(
    ContinueWatchQueue queue,
    int start, {
    required bool forward,
  }) {
    var index = start;
    while (index >= 0 && index < queue.items.length) {
      final item = queue.items[index];
      if (item.selected && item.eligible) return index;
      index += forward ? 1 : -1;
    }
    return null;
  }

  static int _firstPlayableIndex(List<ContinueWatchItem> items) {
    final index = items.indexWhere((item) => item.selected && item.eligible);
    return index < 0 ? 0 : index;
  }

  void _resetQueue(ContinueWatchQueue queue) {
    for (final item in queue.items) {
      item.progressSeconds = 0;
      item.status = item.eligible
          ? ContinueWatchItemStatus.pending
          : ContinueWatchItemStatus.excluded;
    }
    queue.currentIndex = _firstPlayableIndex(queue.items);
    queue.status = ContinueWatchQueueStatus.ready;
    queue.lastPlayedAt = DateTime.now();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_queues.map((queue) => queue.toJson()).toList()),
    );
    if (_activeQueueId == null) {
      await prefs.remove(_activeQueueKey);
    } else {
      await prefs.setString(_activeQueueKey, _activeQueueId!);
    }
  }
}
