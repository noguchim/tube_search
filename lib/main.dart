// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/providers/banner_ad_provider.dart';
import 'package:tube_search/providers/iap_provider.dart';
import 'package:tube_search/providers/region_provider.dart';
import 'package:tube_search/providers/repeat_provider.dart';
import 'package:tube_search/services/iap_products.dart';
import 'package:tube_search/services/iap_service.dart';
import 'package:tube_search/utils/app_logger.dart';
import 'package:tube_search/widgets/ad_banner.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/favorites_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'theme/app_theme.dart';

/// ----------------------------------------------------------------
/// 📝 UMP（同意管理）
/// ----------------------------------------------------------------
Future<void> _requestConsent() async {
  final consentInfo = ConsentInformation.instance;

  final params = ConsentRequestParameters(
    tagForUnderAgeOfConsent: false,
  );

  // 1️⃣ 同意情報リクエスト
  final completer1 = Completer<void>();

  consentInfo.requestConsentInfoUpdate(
    params,
    () {
      // 成功
      completer1.complete();
    },
    (FormError error) {
      logger.i('⚠️ UMP request error: ${error.message}');
      completer1.complete();
    },
  );

  await completer1.future;

  // 👇 ここで状態を確認！
  final status = await ConsentInformation.instance.getConsentStatus();
  logger.i('🔎 consent status = $status');

  // 2️⃣ フォームが必要ならロード
  if (await consentInfo.isConsentFormAvailable()) {
    final completer2 = Completer<ConsentForm>();

    ConsentForm.loadConsentForm(
      (ConsentForm form) {
        completer2.complete(form);
      },
      (FormError error) {
        logger.i('⚠️ UMP form load error: ${error.message}');
        completer2.completeError(error);
      },
    );

    final form = await completer2.future;

    // 3️⃣ 表示
    form.show(
      (FormError? error) {
        if (error != null) {
          logger.i('⚠️ UMP show error: ${error.message}');
        }
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 ここ（テスト端末登録）
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['9ece5c366fa9bdadad267b8e1043760c']),
  );

  await MobileAds.instance.initialize();

  // ⭐ GDPR / UMP（EU圏のみ自動で表示）
  await _requestConsent();

  final favorites = FavoritesService();
  await favorites.loadFavorites();

  // ★ ThemeProvider を先に生成
  final themeProvider = ThemeProvider();

  // ★ 保存済みテーマをロード（ここが最重要）
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RepeatProvider()..init()),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider.value(value: favorites),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => BannerAdProvider()),

        // ★ IapService + IapProvider
        ChangeNotifierProvider(
          create: (_) {
            final provider = IapProvider(IapService());

            provider.init(
              onPurchased: (product) {
                // 👇 ここでは UI 表示不要（静かに状態だけ復元）
                // でも「ログは残す」と後で助かる
                logger.i('[MAIN] restored: ${product.id}');
              },
              onError: (msg) {
                logger.i('[MAIN] IAP error: $msg');
              },
            );

            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegionProvider>().initFromLocale(context);
    });

    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],

      debugShowCheckedModeBanner: false,
      title: 'TUBE+',

      // 🍀 Light / Dark テーマを適用
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeProvider.themeMode,
      // ← Provider で切替

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
  final PageController _pageController = PageController();
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
    final bannerLoaded = context.watch<BannerAdProvider>().isLoaded;
    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final bool shouldShowBanner =
            (!adsRemoved) && (!isKeyboardVisible) && bannerLoaded;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // 背景
              Positioned.fill(child: _buildBackground(context)),

              // メイン画面
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                    _isScrollingDown = false;

                    if (index == 2) {
                      _favKey.currentState?.reload();
                    }
                  },
                  children: _screens,
                ),
              ),

              // ★ BottomNav（キーボード表示中は隠す）
              if (!isKeyboardVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: shouldShowBanner ? 50 : 0, // ← 広告分だけ上げる
                  child: AnimatedOpacity(
                    opacity: _isScrollingDown ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: _isScrollingDown,
                      child: SizedBox(
                        height: 65,
                        child: GlassDockNavigationBar(
                          selectedIndex: _selectedIndex,
                          onTabSelected: (index) {
                            setState(() => _selectedIndex = index);

                            if (index == 2) {
                              _favKey.currentState?.reload();
                            }

                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

              // ★ Divider（広告の直上に 1px）
              if (shouldShowBanner)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 50, // ← バナーの高さ
                  child: _BottomAdDivider(),
                ),

              // ★ バナー広告
              if (shouldShowBanner)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AdBanner(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomAdDivider extends StatelessWidget {
  const _BottomAdDivider();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 2, // ← ここがポイント（極薄の帯）
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.05),
                ]
              : [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.02),
                ],
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

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.7);

    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.07);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 65,
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
  // 🔥 タブ描画（花瓶問題を解消した“丸い”バブル）
  // ---------------------------------------------------------
  Widget _buildTab(BuildContext context, int index, IconData icon) {
    final bool isActive = selectedIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color inactiveIcon =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color inactiveText =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    final l = AppLocalizations.of(context)!;

    final labels = [
      l.navPopular,
      l.navGenre,
      l.navFavorites,
      l.navSettings,
    ];

    // ❤️ お気に入りだけ 1pt 小さく & 少し下げる補正は維持
    final double iconSize = isActive ? (index == 2 ? 21 : 22) : 18;

    final double iconYOffset = (index == 2) ? 2.0 : 0.0;

    // ✨ ライトテーマでは発光強め、ダークでは現状維持寄り
    final double bubbleInnerAlpha = isDark ? 0.28 : 0.55;
    final double bubbleOuterAlpha = isDark ? 0.08 : 0.20;
    final double glowAlpha = isDark ? 0.25 : 0.35;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 🟣 ぼかし入りの丸いバブル
                  if (isActive)
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white
                                    .withValues(alpha: bubbleInnerAlpha),
                                Colors.white
                                    .withValues(alpha: bubbleOuterAlpha),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.30 : 0.55,
                              ),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 🌕 足元の発光（ライトでかなり強め）
                  if (isActive)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            radius: 0.95,
                            colors: [
                              primary.withValues(alpha: glowAlpha),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 🖼 アイコン本体（お気に入りだけ少し下げて描画）
                  Transform.translate(
                    offset: Offset(0, iconYOffset),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: isActive ? primary : inactiveIcon,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primary : inactiveText,
              ),
              child: Text(labels[index]),
            ),
          ],
        ),
      ),
    );
  }
}
