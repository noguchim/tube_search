// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// 🌞 Light Theme
final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  scaffoldBackgroundColor: const Color(0xFFFAF5EF),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFFEF4444),
    secondary: Color(0xFFFF8C66),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Color(0xFF1F1F1F),
  ),

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

  // ★★ あなたの Flutter バージョンでは CardThemeData が正解！！
  cardTheme: const CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    elevation: 3,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),
);


/// ------------------------------------------------------------
/// 🌙 Dark Theme
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  scaffoldBackgroundColor: const Color(0xFF282828),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEF4444),
    secondary: Color(0xFFFF8C66),
    surface: Color(0xFF161616),   // ← これ重要
    onPrimary: Colors.white,
    onSurface: Color(0xFFE5E5E5),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: null,  // ★★★ これが重要
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
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

  // ★★ Dark 用 CardTheme（Glass UI 最適化）
  cardTheme: CardThemeData(
    color: Colors.white.withValues(alpha: 0.08), // ← 背景より少し明るい透明カード
    elevation: 0, // Glass デザインのため影は不要
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),

    // ★ 重要：境界線（ボーダー）は shape → side で指定する！
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.05), // ← 極薄ラインでカードを浮かせる
        width: 1,
      ),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);


/// ------------------------------------------------------------
/// 🎨 セクション装飾（Dark / Light 対応版）
/// ------------------------------------------------------------
BoxDecoration sectionContainerDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  if (!isDark) {
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
  } else {
    return BoxDecoration(
      color: const Color(0xFF242424),
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF303030),
          Color(0xFF1F1F1F),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0xAA000000),
          offset: Offset(3, 3),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0x22000000),
          offset: Offset(-3, -3),
          blurRadius: 8,
        ),
      ],
    );
  }
}
