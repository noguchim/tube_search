import 'dart:ui';
import 'package:flutter/material.dart';
import 'config/screen_titles.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TUBE+',
      theme: appTheme,
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
  bool glassMode = true;

  late final List<Widget> _screens = [
    PopularVideosScreen(onScrollChanged: _onScrollChanged),
    GenreScreen(),
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

          // ★ 画面キャッシュ完全復活（超重要）
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6FFFFFF),
                Color(0xCCE5E8EC),
                Color(0x99D0D4D9),
              ],
            ),
            color: const Color(0xFFF9FAFB).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
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
              _buildTab(context, 2, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, IconData icon) {
    final bool isActive = selectedIndex == index;
    final Color primary = Theme.of(context).colorScheme.primary;

    // ラベル文字
    final labels = [
      ScreenTitles.navLabels['home'],
      ScreenTitles.navLabels['genre'],
      ScreenTitles.navLabels['settings'],
    ];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 上段：アイコン + バブル ---
            SizedBox(
              height: 30, // ← アイコン24pxに合わせて少しだけ拡大
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ● バブル本体（30px）
                  if (isActive)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: 30,   // ← 24px 用に拡大
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.42),
                                Colors.white.withValues(alpha: 0.14),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ● 下グロー（22px）
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
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ● 上ハイライト（14px）
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
                            colors: [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ● アイコン（24px / 18px）
                  Icon(
                    icon,
                    size: isActive ? 24 : 18, // ← ここだけ大きくする！
                    color: isActive ? primary : Colors.grey.shade700,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            // --- 下段：ラベル ---
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primary : Colors.grey.shade700,
                shadows: isActive
                    ? [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 5,
                  ),
                ]
                    : [],
              ),
              child: Text(labels[index] ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}


