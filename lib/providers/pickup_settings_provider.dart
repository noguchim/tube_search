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
    _pendingPickupKey = pickupKey;
    _pendingVideoId = videoId;
    _revision++;
    notifyListeners();
  }

  void clearPendingPush() {
    _pendingPickupKey = null;
    _pendingVideoId = null;
    notifyListeners();
  }
}
