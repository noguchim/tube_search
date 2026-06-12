import 'package:flutter/cupertino.dart';

class PickupSettingsProvider extends ChangeNotifier {
  int _revision = 0;
  String? _pendingPickupKey;
  String? _pendingVideoId;

  int get revision => _revision;

  String? get pendingPickupKey => _pendingPickupKey;

  String? get pendingVideoId => _pendingVideoId;

  void notifyChanged() {
    _revision++;
    notifyListeners();
  }

  void openFromPush({
    required String pickupKey,
    required String videoId,
  }) {
    _pendingPickupKey = _normalizePickupKey(pickupKey);
    _pendingVideoId = videoId;
    _revision++;
    notifyListeners();
  }

  void clearPendingPush() {
    _pendingPickupKey = null;
    _pendingVideoId = null;
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
