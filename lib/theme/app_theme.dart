import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // 🔸 全体背景：やや温かみのあるアイボリー（赤系と好相性）
  scaffoldBackgroundColor: const Color(0xFFFAF5EF),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFFEF4444), // ❤️ メイン：トマトレッド（鮮やか・高コントラスト）
    secondary: Color(0xFFFF8C66), // 🧡 サブ：コーラルオレンジ（再生数など）
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Color(0xFF1F1F1F),
  ),

  // 🔹 AppBar設定
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

  // 🔹 テキスト全体のトーン
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

  // 🔹 カードテーマ（動画一覧など）
  cardTheme: const CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    elevation: 3,
    shadowColor: Colors.redAccent, // 🔴 赤系シャドウ
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  ),

  // 🔹 ボタンテーマ
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEF4444), // トマトレッド
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),
);

/// ✅ 共通デコレーション：凹み風（ネオモルフィック風）セクション背景
BoxDecoration sectionContainerDecoration(BuildContext context) {
  return BoxDecoration(
    color: const Color(0xFFEAE6E3), // 🩶 ベージュグレー系で赤と調和
    borderRadius: BorderRadius.circular(10),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF7F3F0), // 明るめ（左上光源）
        Color(0xFFDCD6D3), // 暗め（右下影）
      ],
    ),
    boxShadow: const [
      // 💡 下影（右下）
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(3, 3),
        blurRadius: 8,
      ),
      // ☀️ 上光（左上）
      BoxShadow(
        color: Color(0xFFFFFFFF),
        offset: Offset(-3, -3),
        blurRadius: 8,
      ),
    ],
  );
}
