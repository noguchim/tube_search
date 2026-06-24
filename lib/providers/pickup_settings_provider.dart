import 'package:flutter/cupertino.dart';

class PickupSettingsProvider extends ChangeNotifier {
  int _revision = 0;
  String? _pendingPickupKey;
  String? _pendingVideoId;
  Set<String> _pendingPickupKeys = <String>{};

  int get revision => _revision;

  String? get pendingPickupKey => _pendingPickupKey;

  String? get pendingVideoId => _pendingVideoId;

  Set<String> get pendingPickupKeys => Set.unmodifiable(_pendingPickupKeys);

  void notifyChanged() {
    _revision++;
    notifyListeners();
  }

  void openFromPush({
    required String pickupKey,
    required String videoId,
    List<String> pickupKeys = const [],
  }) {
    final normalizedKeys = <String>{
      for (final key in pickupKeys)
        if (_normalizePickupKey(key).isNotEmpty) _normalizePickupKey(key),
    };

    final normalizedPickupKey = _normalizePickupKey(pickupKey);
    if (normalizedPickupKey.isNotEmpty) {
      normalizedKeys.add(normalizedPickupKey);
    }

    _pendingPickupKeys = normalizedKeys;
    _pendingPickupKey = normalizedPickupKey.isNotEmpty
        ? normalizedPickupKey
        : (normalizedKeys.isEmpty ? null : normalizedKeys.first);
    _pendingVideoId = videoId;
    _revision++;
    notifyListeners();
  }

  void clearPendingPush() {
    _pendingPickupKey = null;
    _pendingVideoId = null;
    _pendingPickupKeys = <String>{};
    notifyListeners();
  }

  void clearPendingPickupKey(String pickupKey) {
    final normalizedKey = _normalizePickupKey(pickupKey);
    if (normalizedKey.isEmpty) return;

    final removed = _pendingPickupKeys.remove(normalizedKey);
    if (!removed && _pendingPickupKey != normalizedKey) return;

    if (_pendingPickupKey == normalizedKey) {
      _pendingPickupKey = null;
      _pendingVideoId = null;
    }

    if (_pendingPickupKeys.isEmpty) {
      _pendingPickupKey = null;
      _pendingVideoId = null;
    }

    notifyListeners();
  }

  String _normalizePickupKey(String key) {
    switch (key) {
      case 'category:all':
      case 'category:recommended':
        return 'recommended';
      case 'category:20':
        return 'game';
      case 'category:10':
        return 'music';
      default:
        return key;
    }
  }
}
