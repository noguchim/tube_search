import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefThemeMode = "theme_mode";

  /// デフォルト：ライト
  ThemeMode _themeMode = ThemeMode.light;

  /// ★ MyApp から参照するプロパティ
  ThemeMode get themeMode => _themeMode;

  /// 初期ロード
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefThemeMode) ?? "light";

    if (value == "dark") {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  /// テーマ変更
  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    if (mode == ThemeMode.dark) {
      await prefs.setString(_prefThemeMode, "dark");
    } else {
      await prefs.setString(_prefThemeMode, "light");
    }

    _themeMode = mode;
    notifyListeners();
  }
}
