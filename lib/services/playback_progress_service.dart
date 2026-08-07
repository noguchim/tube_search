import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackProgressService extends ChangeNotifier {
  static const String storageKey = 'playback_progress_v1';
  static const Duration retention = Duration(days: 30);
  static const int maxItems = 500;
  static const int minimumProgressSeconds = 10;
  static const int completionThresholdSeconds = 5;

  final Map<String, _PlaybackProgressEntry> _entries = {};
  bool _loaded = false;

  double progressFractionSync(String videoId, {int? durationSeconds}) {
    if (!_loaded) return 0;
    final entry = _entries[videoId];
    if (entry == null) return 0;
    final duration = durationSeconds ?? entry.durationSeconds;
    if (duration == null || duration <= 0) return 0;
    return (entry.progressSeconds / duration).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final value in decoded) {
          final entry = _PlaybackProgressEntry.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          if (entry.videoId.isNotEmpty) {
            _entries[entry.videoId] = entry;
          }
        }
      } catch (error) {
        debugPrint('[PlaybackProgressService] load failed: $error');
      }
    }

    _loaded = true;
    final changed = _cleanup();
    if (changed) await _save();
    notifyListeners();
  }

  Future<int> resumeSeconds(String videoId, {int? durationSeconds}) async {
    await load();
    final entry = _entries[videoId];
    if (entry == null) return 0;

    final duration = durationSeconds ?? entry.durationSeconds;
    if (_isCompleted(entry.progressSeconds, duration)) return 0;
    return entry.progressSeconds;
  }

  Future<void> saveProgress(
    String videoId, {
    required int progressSeconds,
    int? durationSeconds,
  }) async {
    if (videoId.isEmpty || progressSeconds < minimumProgressSeconds) return;
    await load();

    final existing = _entries[videoId];
    final duration = durationSeconds != null && durationSeconds > 0
        ? durationSeconds
        : existing?.durationSeconds;
    final clamped = duration == null
        ? progressSeconds
        : progressSeconds.clamp(0, duration);
    _entries[videoId] = _PlaybackProgressEntry(
      videoId: videoId,
      progressSeconds: clamped,
      durationSeconds: duration,
      updatedAt: DateTime.now(),
    );
    _cleanup();
    await _save();
    notifyListeners();
  }

  Future<void> markCompleted(
    String videoId, {
    required int durationSeconds,
  }) async {
    if (videoId.isEmpty || durationSeconds <= 0) return;
    await saveProgress(
      videoId,
      progressSeconds: durationSeconds,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> reset(String videoId) async {
    await resetAll([videoId]);
  }

  Future<void> resetAll(Iterable<String> videoIds) async {
    await load();
    var changed = false;
    for (final videoId in videoIds) {
      if (_entries.remove(videoId) != null) changed = true;
    }
    if (!changed) return;
    await _save();
    notifyListeners();
  }

  bool _cleanup() {
    var changed = false;
    final cutoff = DateTime.now().subtract(retention);
    _entries.removeWhere((_, entry) {
      final expired = entry.updatedAt.isBefore(cutoff);
      if (expired) changed = true;
      return expired;
    });

    if (_entries.length > maxItems) {
      final oldest = _entries.values.toList()
        ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      for (final entry in oldest.take(_entries.length - maxItems)) {
        _entries.remove(entry.videoId);
        changed = true;
      }
    }
    return changed;
  }

  bool _isCompleted(int progressSeconds, int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return false;
    return durationSeconds - progressSeconds <= completionThresholdSeconds;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _entries.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setString(
      storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

class _PlaybackProgressEntry {
  final String videoId;
  final int progressSeconds;
  final int? durationSeconds;
  final DateTime updatedAt;

  const _PlaybackProgressEntry({
    required this.videoId,
    required this.progressSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'progressSeconds': progressSeconds,
    'durationSeconds': durationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory _PlaybackProgressEntry.fromJson(Map<String, dynamic> json) {
    return _PlaybackProgressEntry(
      videoId: json['videoId']?.toString() ?? '',
      progressSeconds: _asInt(json['progressSeconds']) ?? 0,
      durationSeconds: _asInt(json['durationSeconds']),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
