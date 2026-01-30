// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// 🌞 Light Theme（フラット確定：F2F2F6背景 / EF4444はピンポイント）
/// ------------------------------------------------------------

// Spotify参考
// const Color colorDarkGray = Color(0xFF282828);
// const Color colorGray = Color(0xFFB3B3B3);
// const Color colorLightGray = Color(0xFFEEEEEE);
// const Color colorLightBlue = Color(0xFFD3E3FD);
const Color splashBack = Color(0xFF4F6BFF);
const Color splashBack2 = Color(0xFF355CFF);

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // ✅ ここはあなたの決定を最優先（上質な背景）
  scaffoldBackgroundColor: const Color(0xFFF2F2F6),

  // ✅ divider / outline は寒色系グレーで統一
  dividerColor: const Color(0xFFECECEC),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFECECEC),
    thickness: 1,
    space: 1,
  ),

  extensions: const <ThemeExtension<dynamic>>[
    AppColors.light,
  ],

  // ✅ primary（テーマカラー）は定義するが、UIでは「ピンポイントで使用」
  // ＝Themeに入れておくとActive色/CTAで使えて便利
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFEF4444),
    secondary: Color(0xFFFF8C66),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111111),
    background: Color(0xFFF2F2F6),
    onBackground: Color(0xFF111111),
    onPrimary: Colors.white,
  ),

  // ✅ AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEAF0FF),
    // 明るいブルーグレー
    foregroundColor: Color(0xFF1F2937),
    // 濃いグレー（ほぼ黒）
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Color(0xFF1F2937),
    ),
  ),

  // ✅ テキストは黒系2段（読みやすさ優先）
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFF111111),
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFF222222),
      fontSize: 14,
    ),
  ),

  // ✅ Card：白＋薄線（影なし）
  // 背景F2F2F6とのコントラストで階層が作れる
  cardTheme: const CardThemeData(
    color: Color(0xFFFFFFFF),
    elevation: 0,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      side: BorderSide(
        color: Color(0xFFECECEC),
        width: 1,
      ),
    ),
  ),

  // ✅ ボタンはブランド色（ここは主役なのでEF4444 OK）
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
/// 🌙 Dark Theme（基本維持：Light方針と整合）
/// ------------------------------------------------------------
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  scaffoldBackgroundColor: const Color(0xFF282828),

  dividerColor: Colors.white.withValues(alpha: 0.12),
  dividerTheme: DividerThemeData(
    color: Colors.white.withValues(alpha: 0.12),
    thickness: 1,
    space: 1,
  ),

  extensions: <ThemeExtension<dynamic>>[
    AppColors.dark,
  ],

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEF4444),
    secondary: Color(0xFFFF8C66),
    surface: Color(0xFF161616),
    onPrimary: Colors.white,
    onSurface: Color(0xFFE5E5E5),
  ),

  // ✅ DarkはGlass AppBar前提
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF303030),
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

  // ✅ Dark card（現状維持でOK）
  cardTheme: CardThemeData(
    color: Colors.white.withValues(alpha: 0.08),
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.05),
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
/// 🎨 セクション装飾（Light：フラット / Dark：現状活用）
/// ------------------------------------------------------------
BoxDecoration sectionContainerDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  if (!isDark) {
    // ✅ Light：背景F2F2F6に対して “EEEEEF面” を作る
    // 余計なグラデ・影は封印 → あとで薄いガラス化する余地が残る
    return BoxDecoration(
      color: const Color(0xFFEEEEEF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFECECEC),
        width: 1,
      ),
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

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color label;

  const AppColors({
    required this.label,
  });

  // ✅ ライト：iOS/ChatGPT的なラベルグレー
  static const light = AppColors(
    label: Color(0xFF8E8E93),
  );

  static final dark = AppColors(
    label: Colors.white.withValues(alpha: 0.75),
  );

  @override
  AppColors copyWith({Color? label}) {
    return AppColors(
      label: label ?? this.label,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      label: Color.lerp(label, other.label, t)!,
    );
  }
}
