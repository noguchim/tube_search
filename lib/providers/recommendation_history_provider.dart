import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendationSignalType {
  static const String searchKeyword = 'search_keyword';
  static const String channel = 'channel';
  static const String category = 'category';
}

class RecommendationSignal {
  final String type;
  final String value;
  final String label;
  final int count;
  final DateTime lastUsedAt;

  const RecommendationSignal({
    required this.type,
    required this.value,
    required this.label,
    required this.count,
    required this.lastUsedAt,
  });

  String get identity => '$type:$value';

  double get score {
    final ageHours = DateTime.now().difference(lastUsedAt).inHours;
    final recency = 1 / (1 + (ageHours / 24));
    return count + recency;
  }

  RecommendationSignal copyWith({
    String? label,
    int? count,
    DateTime? lastUsedAt,
  }) {
    return RecommendationSignal(
      type: type,
      value: value,
      label: label ?? this.label,
      count: count ?? this.count,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'label': label,
      'count': count,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory RecommendationSignal.fromJson(Map<String, dynamic> json) {
    return RecommendationSignal(
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      count: int.tryParse('${json['count'] ?? 1}') ?? 1,
      lastUsedAt: DateTime.tryParse(json['lastUsedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RecommendationHistoryProvider extends ChangeNotifier {
  static const String _historyKey = 'recommendation_history_v1';
  static const String _pickupSelectedPrefsKey = 'pickup_selected_items';
  static const int _maxItems = 40;

  final List<RecommendationSignal> _signals = [];
  bool _loaded = false;

  List<RecommendationSignal> get signals => List.unmodifiable(_signals);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _signals
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((e) => RecommendationSignal.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((signal) {
            return signal.type.isNotEmpty && signal.value.isNotEmpty;
          }),
        );

      _sortAndTrim();
      notifyListeners();
    } catch (_) {
      // Broken local history should not affect app startup.
    }
  }

  Future<void> recordSearchKeyword(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) return;

    await _record(
      type: RecommendationSignalType.searchKeyword,
      value: value,
      label: value,
    );
  }

  Future<void> recordGenreTap({
    required String categoryId,
    required String title,
  }) async {
    final value = categoryId.trim();
    if (value.isEmpty) return;
    if (await _isPickupRegistered('category:$value')) return;

    await _record(
      type: RecommendationSignalType.category,
      value: value,
      label: title.trim().isEmpty ? value : title.trim(),
    );
  }

  Future<void> recordVideoTap({
    required String videoId,
    required String title,
    String? channelId,
    String? channelTitle,
    String? categoryId,
    String? categoryTitle,
  }) async {
    final normalizedChannelId = channelId?.trim() ?? '';
    final normalizedChannelTitle = channelTitle?.trim() ?? '';
    final normalizedCategoryId = categoryId?.trim() ?? '';
    final exclusions = await _loadPickupExclusions();

    if (normalizedChannelId.isNotEmpty &&
        !exclusions.keys.contains('channel:$normalizedChannelId')) {
      await _record(
        type: RecommendationSignalType.channel,
        value: normalizedChannelId,
        label: normalizedChannelTitle.isEmpty
            ? title.trim()
            : normalizedChannelTitle,
      );
    } else if (normalizedChannelTitle.isNotEmpty &&
        !exclusions.labels.contains(normalizedChannelTitle.toLowerCase())) {
      await _record(
        type: RecommendationSignalType.searchKeyword,
        value: normalizedChannelTitle,
        label: normalizedChannelTitle,
      );
    }

    if (normalizedCategoryId.isNotEmpty &&
        !exclusions.keys.contains('category:$normalizedCategoryId')) {
      await _record(
        type: RecommendationSignalType.category,
        value: normalizedCategoryId,
        label: categoryTitle?.trim().isNotEmpty == true
            ? categoryTitle!.trim()
            : normalizedCategoryId,
      );
    }
  }

  List<RecommendationSignal> topSignals({int limit = 5}) {
    final sorted = [..._signals]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).toList(growable: false);
  }

  Future<List<RecommendationSignal>> topSignalsForRecommendation({
    int limit = 5,
  }) async {
    await load();

    final exclusions = await _loadPickupExclusions();
    final sorted = [..._signals]..sort((a, b) => b.score.compareTo(a.score));

    return sorted
        .where((signal) => !_isExcludedByPickup(signal, exclusions))
        .take(limit)
        .toList(growable: false);
  }

  Future<RecommendationExcludeTargets> pickupExcludeTargets() async {
    final exclusions = await _loadPickupExclusions();
    return RecommendationExcludeTargets(
      channelIds: exclusions.channelIds,
      categoryIds: exclusions.categoryIds,
    );
  }

  Future<void> clear() async {
    _signals.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> _record({
    required String type,
    required String value,
    required String label,
  }) async {
    await load();

    final now = DateTime.now();
    final identity = '$type:$value';
    final index = _signals.indexWhere((signal) => signal.identity == identity);

    if (index >= 0) {
      final current = _signals[index];
      _signals[index] = current.copyWith(
        label: label,
        count: current.count + 1,
        lastUsedAt: now,
      );
    } else {
      _signals.add(
        RecommendationSignal(
          type: type,
          value: value,
          label: label,
          count: 1,
          lastUsedAt: now,
        ),
      );
    }

    _sortAndTrim();
    notifyListeners();
    await _save();
  }

  void _sortAndTrim() {
    _signals.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    if (_signals.length > _maxItems) {
      _signals.removeRange(_maxItems, _signals.length);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_signals.map((signal) => signal.toJson()).toList()),
    );
  }

  Future<bool> _isPickupRegistered(String key) async {
    if (key == 'category:recommended' || key == 'category:all') return false;

    final exclusions = await _loadPickupExclusions();
    return exclusions.keys.contains(key);
  }

  Future<_PickupRecommendationExclusions> _loadPickupExclusions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSelectedPrefsKey);
    if (raw == null || raw.isEmpty) {
      return const _PickupRecommendationExclusions();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const _PickupRecommendationExclusions();

      final keys = <String>{};
      final labels = <String>{};
      final channelIds = <String>{};
      final categoryIds = <String>{};

      for (final item in decoded.whereType<Map>()) {
        final pickupKey = item['key']?.toString() ?? '';
        if (pickupKey == 'category:recommended' ||
            pickupKey == 'category:all') {
          continue;
        }
        if (pickupKey.isNotEmpty) {
          keys.add(pickupKey);
        }

        if (pickupKey.startsWith('channel:')) {
          final channelId = pickupKey.substring('channel:'.length).trim();
          if (channelId.isNotEmpty) {
            channelIds.add(channelId);
          }
        } else if (pickupKey.startsWith('category:')) {
          final categoryId = pickupKey.substring('category:'.length).trim();
          if (categoryId.isNotEmpty) {
            categoryIds.add(categoryId);
          }
        }

        final title = item['title']?.toString().trim() ?? '';
        if (title.isNotEmpty) {
          labels.add(title.toLowerCase());
        }
      }

      return _PickupRecommendationExclusions(
        keys: keys,
        labels: labels,
        channelIds: channelIds,
        categoryIds: categoryIds,
      );
    } catch (_) {
      return const _PickupRecommendationExclusions();
    }
  }

  bool _isExcludedByPickup(
    RecommendationSignal signal,
    _PickupRecommendationExclusions exclusions,
  ) {
    if (signal.type == RecommendationSignalType.channel) {
      return exclusions.keys.contains('channel:${signal.value}');
    }

    if (signal.type == RecommendationSignalType.category) {
      return exclusions.keys.contains('category:${signal.value}');
    }

    if (signal.type == RecommendationSignalType.searchKeyword) {
      final value = signal.value.trim().toLowerCase();
      final label = signal.label.trim().toLowerCase();
      return exclusions.labels.contains(value) ||
          exclusions.labels.contains(label);
    }

    return false;
  }
}

class _PickupRecommendationExclusions {
  final Set<String> keys;
  final Set<String> labels;
  final Set<String> channelIds;
  final Set<String> categoryIds;

  const _PickupRecommendationExclusions({
    this.keys = const {},
    this.labels = const {},
    this.channelIds = const {},
    this.categoryIds = const {},
  });
}

class RecommendationExcludeTargets {
  final Set<String> channelIds;
  final Set<String> categoryIds;

  const RecommendationExcludeTargets({
    this.channelIds = const {},
    this.categoryIds = const {},
  });
}
