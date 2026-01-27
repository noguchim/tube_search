// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/providers/banner_ad_provider.dart';
import 'package:tube_search/providers/iap_provider.dart';
import 'package:tube_search/providers/region_provider.dart';
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

  // ★ ステータスバーを「表示モード」に戻す
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // ★ 白アイコン指定（Android）
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

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

      home: const MainNavigationScreen(),
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // ✅ 起動直後にバックグラウンドでPreload
    Future.microtask(() async {
      try {
        // await VideoPlayerScreen.preloadController();
      } catch (e, st) {
        // 失敗しても起動は継続させる
        logger.w("preloadController error: $e");
        logger.w("$st");
      }
    });

    _screens = [
      PopularVideosScreen(onScrollChanged: _onScrollChanged),
      GenreScreen(onScrollChanged: _onScrollChanged),
      FavoritesScreen(key: _favKey),
      const SettingsScreen(),
    ];
  }

  void _onScrollChanged(bool isScrollingDown) {
    if (_isScrollingDown != isScrollingDown && mounted) {
      setState(() => _isScrollingDown = isScrollingDown);
    }
  }

  /// 🔥 ダークテーマ対応の背景
  // Widget _buildBackground(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final isDark = theme.brightness == Brightness.dark;
  //
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //         colors: isDark
  //             ? [
  //                 const Color(0xFF0F0F0F),
  //                 const Color(0xFF1A1A1A),
  //               ]
  //             : [
  //                 const Color(0xFFE2E8F0),
  //                 const Color(0xFFF8FAFC),
  //               ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBackground(BuildContext context) {
    return Container(
      // color: Theme.of(context).scaffoldBackgroundColor,
      color: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerLoaded = context.watch<BannerAdProvider>().isLoaded;
    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);
    final l = AppLocalizations.of(context)!;

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double topTabHeight = 45;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final bool shouldShowBanner =
            (!adsRemoved) && (!isKeyboardVisible) && bannerLoaded;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // メイン画面（全面）
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  children: _screens,
                ),
              ),

              // ★ 上部タブ（高さ固定）
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: AnimatedOpacity(
                  opacity: _isScrollingDown ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: _isScrollingDown,
                    child: SizedBox(
                      height: 75,
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

              // ★ Divider（広告の直上）
              if (shouldShowBanner)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 50,
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

class GlassDockNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const GlassDockNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    // -------------------------------------------------------------
    // ✅ AppBarと同じガラス背景（流用）
    // -------------------------------------------------------------
    final List<Color> bgGradient = isDark
        ? [
            const Color(0xCC111111),
            const Color(0xB31A1A1A),
            const Color(0x991A1A1A),
          ]
        : [
            // const Color(0xE6FFFFFF),
            // const Color(0xCCE5E8EC),
            // const Color(0x99D0D4D9),
            const Color(0xE60B3BDF),
            const Color(0xE60B3BDF),
            const Color(0xE60B3BDF),
          ];

    // ✅ BottomNavは“霧っぽく”見えやすいので、まずはAppBarより少し薄くして開始
    // （AppBar 0.85 → BottomNavは 0.78 くらいが起点として安全）
    // final Color bgColor = isDark
    //     ? const Color(0xFF111111).withValues(alpha: 0.78)
    //     : const Color(0xFFF9FAFB).withValues(alpha: 0.78);

    final Color bgColor = isDark ? Colors.red : Colors.red;

    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFECECEC);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // -------------------------------------------------------------
          // 🪩 ガラス背景（AppBarと同型）
          // -------------------------------------------------------------
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: bgGradient,
                  ),
                  color: bgColor,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTab(
                      context,
                      index: 0,
                      label: l.navPopular,
                      activeColor: cs.primary,
                    ),
                    _buildTab(
                      context,
                      index: 1,
                      label: l.navGenre,
                      activeColor: cs.primary,
                    ),
                    _buildTab(
                      context,
                      index: 2,
                      label: l.navFavorites,
                      activeColor: cs.primary,
                    ),
                    _buildTab(
                      context,
                      index: 3,
                      label: l.navSettings,
                      activeColor: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔥 タブ描画（現行のまま維持：視認性担保）
  // ---------------------------------------------------------
  Widget _buildTab(
    BuildContext context, {
    required int index,
    required String label,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = selectedIndex == index;

    // final inactiveText = isDark
    //     ? Colors.white.withValues(alpha: 0.62)
    //     : Colors.black.withValues(alpha: 0.52);
    //
    // final textColor = isActive ? activeColor : inactiveText;

    const inactiveText = Colors.white;

    final textColor = Colors.white;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onTabSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(
              //   height: 30,
              //   child: Align(
              //     alignment: Alignment.center,
              //     child: Transform.translate(
              //       offset: Offset(0, iconYOffset),
              //       child: Icon(
              //         icon,
              //         size: iconSize,
              //         color: iconColor,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 40),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: textColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
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
