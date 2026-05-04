import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _key = "skip_delete_confirm";

  bool _skipDeleteConfirm = false;

  bool get skipDeleteConfirm => _skipDeleteConfirm;

  String get label => _skipDeleteConfirm ? "確認しない" : "確認する";

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _skipDeleteConfirm = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> update(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);

    _skipDeleteConfirm = value;
    notifyListeners(); // ← 🔥 これが重要
  }
}
