// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/favorites_service.dart';
import 'providers/theme_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';

import 'theme/app_theme.dart';
import 'config/screen_titles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final favorites = FavoritesService();
  await favorites.loadFavorites();

  // ★ ThemeProvider を先に生成
  final themeProvider = ThemeProvider();

  // ★ 保存済みテーマをロード（ここが最重要）
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: favorites),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TUBE+',

      // 🍀 Light / Dark テーマを適用
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeProvider.themeMode, // ← Provider で切替

      home: const SplashScreen(),
    );
  }
}


/// ----------------------------------------------------------------
/// 🧭 BottomNavigation 管理画面（背景のダーク対応を改善済み）
/// ----------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isScrollingDown = false;

  final GlobalKey<FavoritesScreenState> _favKey =
  GlobalKey<FavoritesScreenState>();

  late final List<Widget> _screens = [
    PopularVideosScreen(onScrollChanged: _onScrollChanged),
    GenreScreen(onScrollChanged: _onScrollChanged),
    FavoritesScreen(key: _favKey),
    const SettingsScreen(),
  ];

  void _onScrollChanged(bool isScrollingDown) {
    if (_isScrollingDown != isScrollingDown && mounted) {
      setState(() => _isScrollingDown = isScrollingDown);
    }
  }

  /// 🔥 ダークテーマ対応の背景
  Widget _buildBackground(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
            const Color(0xFF0F0F0F),
            const Color(0xFF1A1A1A),
          ]
              : [
            const Color(0xFFE2E8F0),
            const Color(0xFFF8FAFC),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context)),
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),

      // 🍀 BottomNav フェード
      bottomNavigationBar: AnimatedOpacity(
        opacity: _isScrollingDown ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: _isScrollingDown,
          child: GlassDockNavigationBar(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() => _selectedIndex = index);
              if (index == 2) _favKey.currentState?.reload();
            },
          ),
        ),
      ),
    );
  }
}

class GlassDockNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const GlassDockNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // ---------------------------------------------------------
    // 🎨 Light / Dark 背景グラデーション
    // ---------------------------------------------------------
    final List<Color> bgGradient = isDark
        ? [
            const Color(0xCC111111),
            const Color(0xB31A1A1A),
            const Color(0x991A1A1A),
          ]
        : [
            const Color(0xE6FFFFFF),
            const Color(0xCCE5E8EC),
            const Color(0x99D0D4D9),
          ];

    final Color bgColor = isDark
        ? const Color(0xFF111111).withValues(alpha: 0.85)
        : const Color(0xFFF9FAFB).withValues(alpha: 0.85);

    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.7);

    final Color shadowColor =
        isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.07);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradient,
            ),
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(context, 0, Icons.local_fire_department_rounded),
              _buildTab(context, 1, Icons.category_rounded),
              _buildTab(context, 2, Icons.favorite_rounded),
              _buildTab(context, 3, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔥 タブ描画
  // ---------------------------------------------------------
  Widget _buildTab(BuildContext context, int index, IconData icon) {
    final bool isActive = selectedIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color inactiveIcon =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color inactiveText =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    final labels = [
      ScreenTitles.navLabels['home'],
      ScreenTitles.navLabels['genre'],
      "お気に入り",
      ScreenTitles.navLabels['settings'],
    ];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---------------------------------------------
            // 🔵 Active バブル（光の玉 + 背景）
            // ---------------------------------------------
            SizedBox(
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (isActive)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.05),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.42),
                                      Colors.white.withValues(alpha: 0.14),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.30)
                                  : Colors.white.withValues(alpha: 0.55),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (isActive)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            radius: 0.85,
                            colors: [
                              primary.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (isActive)
                    Positioned(
                      top: 1.4,
                      child: Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.60),
                                    Colors.white.withValues(alpha: 0.0),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.75),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                          ),
                        ),
                      ),
                    ),

                  // アイコン
                  Icon(
                    icon,
                    size: isActive ? 24 : 18,
                    color: isActive ? primary : inactiveIcon,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            // ---------------------------------------------
            // 🏷 ラベル
            // ---------------------------------------------
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primary : inactiveText,
              ),
              child: Text(labels[index] ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
