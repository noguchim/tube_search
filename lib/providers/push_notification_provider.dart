import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationProvider extends ChangeNotifier {
  static const _key = "push_notification_enabled";

  bool _enabled = true;

  bool get enabled => _enabled;

  String get label => _enabled ? "ON" : "OFF";

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> update(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);

    _enabled = value;
    notifyListeners();
  }
}
