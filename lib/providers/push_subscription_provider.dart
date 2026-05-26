import 'package:flutter/cupertino.dart';

class PushSubscriptionProvider extends ChangeNotifier {
  final Set<String> _enabledKeys = {};
  bool _loaded = false;

  Set<String> get enabledKeys => Set.unmodifiable(_enabledKeys);

  bool get loaded => _loaded;

  bool isEnabled(String key) => _enabledKeys.contains(key);

  void setEnabledKeys(Iterable<String> keys) {
    _enabledKeys
      ..clear()
      ..addAll(keys);
    _loaded = true;
    notifyListeners();
  }

  void replaceEnabledKeys(Iterable<String> keys) {
    _enabledKeys
      ..clear()
      ..addAll(keys);
    notifyListeners();
  }

  void clear() {
    _enabledKeys.clear();
    _loaded = false;
    notifyListeners();
  }
}
