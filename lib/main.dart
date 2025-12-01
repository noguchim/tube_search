import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/services/favorites_service.dart';

import 'config/screen_titles.dart';
import 'providers/theme_provider.dart'; // ★ NEW 追加
import 'screens/favorites_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ 初期ロード済のお気に入りサービスを作成
  final fav = FavoritesService();
  await fav.loadFavorites();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fav),
        // ★ FavoritesService
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // ★ ThemeProvider 追加
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ★ ThemeProvider を監視
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TUBE+',
      theme: appLightTheme,
      // ★ Light
      darkTheme: appDarkTheme,
      // ★ Dark
      themeMode: themeProvider.themeMode,
      // ★ ON/OFF 自動反映
      home: const SplashScreen(),
    );
  }
}

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

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
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
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedOpacity(
        opacity: _isScrollingDown ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: _isScrollingDown,
          child: GlassDockNavigationBar(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() => _selectedIndex = index);

              if (index == 2) {
                _favKey.currentState?.reload();
              }
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
        ? const Color(0xFF111111).withOpacity(0.85)
        : const Color(0xFFF9FAFB).withOpacity(0.85);

    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.7);

    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.07);

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
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.05),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.42),
                                      Colors.white.withOpacity(0.14),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.30)
                                  : Colors.white.withOpacity(0.55),
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
                              primary.withOpacity(0.22),
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
                                    Colors.white.withOpacity(0.60),
                                    Colors.white.withOpacity(0.0),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.75),
                                    Colors.white.withOpacity(0.0),
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
