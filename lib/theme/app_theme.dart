// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// 🌞 Light Theme（あなたのテーマをベースに最適構成）
final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // 🔸 全体背景：暖かみのあるアイボリー
  scaffoldBackgroundColor: const Color(0xFFFAF5EF),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFFEF4444),
    // ❤️ トマトレッド
    secondary: Color(0xFFFF8C66),
    // 🧡 コーラルオレンジ
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Color(0xFF1F1F1F),
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEF4444),
    foregroundColor: Colors.white,
    elevation: 1,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  // Text
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFF1F1F1F),
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFF2D2D2D),
      fontSize: 14,
    ),
  ),

  // カード（※CardThemeData → CardTheme に修正）
  cardTheme: const CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    elevation: 3,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  ),

  // ボタン
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFEF4444),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),
);

/// ------------------------------------------------------------
/// 🌙 Dark Theme（Light の世界観を維持しつつ落ち着いた暗色に最適化）
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  scaffoldBackgroundColor: const Color(0xFF1A1A1A),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEF4444),
    // ❤️ 共通赤
    secondary: Color(0xFFFF8C66),
    surface: Color(0xFF262626),
    onPrimary: Colors.white,
    onSurface: Color(0xFFE5E5E5),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2C2C2C),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 14,
    ),
  ),

  // カード（※CardThemeData → CardTheme に修正）
  cardTheme: const CardThemeData(
    color: Color(0xFF262626),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    elevation: 1,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFEF4444),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);

/// ------------------------------------------------------------
/// 🎨 共通デコレーション（Light 専用のままで OK）
BoxDecoration sectionContainerDecoration(BuildContext context) {
  return BoxDecoration(
    color: const Color(0xFFEAE6E3),
    borderRadius: BorderRadius.circular(10),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF7F3F0),
        Color(0xFFDCD6D3),
      ],
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(3, 3),
        blurRadius: 8,
      ),
      BoxShadow(
        color: Color(0xFFFFFFFF),
        offset: Offset(-3, -3),
        blurRadius: 8,
      ),
    ],
  );
}
