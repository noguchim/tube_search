// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/providers/density_provider.dart';
import 'package:tube_search/providers/iap_provider.dart';
import 'package:tube_search/providers/region_provider.dart';
import 'package:tube_search/screens/settings_screen.dart';
import 'package:tube_search/screens/topic_screen.dart';
import 'package:tube_search/services/expanded_video_controller.dart';
import 'package:tube_search/services/iap_products.dart';
import 'package:tube_search/services/iap_service.dart';
import 'package:tube_search/services/youtube_api_service.dart';
import 'package:tube_search/theme/app_theme.dart';
import 'package:tube_search/utils/app_logger.dart';
import 'package:tube_search/utils/app_version.dart';
import 'package:tube_search/utils/request_review.dart';
import 'package:tube_search/widgets/ad_banner.dart';
import 'package:tube_search/widgets/consent_manager.dart';
import 'package:tube_search/widgets/top_bar.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/favorites_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'services/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob初期化
  // if (AdMobConfig.useTestAds) {
  //   MobileAds.instance.updateRequestConfiguration(
  //     RequestConfiguration(
  //       testDeviceIds: ['D3402AA94C9B637E34B0D3E969158B2A'],
  //     ),
  //   );
  // }
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: [],
    ),
  );

  await MobileAds.instance.initialize();

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

        Provider<YouTubeApiService>(
          create: (_) => YouTubeApiService(),
        ),

        ChangeNotifierProvider(
          create: (_) => ExpandedVideoController(),
        ),

        ChangeNotifierProvider(
          create: (_) {
            final p = DensityProvider();
            p.load();
            return p;
          },
        ),

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegionProvider>().initFromLocale(context);
    });

    // 🔥 初回フレーム後にGDPR実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConsent();
    });
  }

  Future<void> _initConsent() async {
    await ConsentManager.requestConsent();
  }

  @override
  Widget build(BuildContext context) {
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
      title: 'Tube Plus',

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
  bool debugMode = false;

  // late final List<Widget> _screens;
  double _pageProgress = 0.0;
  bool _isTapNavigating = false;
  final GlobalKey _topBarKey = GlobalKey();

  final _topicKey = GlobalKey<TopicScreenState>();
  final _popularKey = GlobalKey<PopularVideosScreenState>();
  final _genreKey = GlobalKey<GenreScreenState>();
  final _favoriteKey = GlobalKey<FavoritesScreenState>();

  // final _settingsKey = GlobalKey<SettingsScreenState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
        TopicScreen(
          onScrollChanged: _onScrollChanged,
          key: _topicKey,
        ),
        PopularVideosScreen(
          onScrollChanged: _onScrollChanged,
          key: _popularKey,
        ),
        GenreScreen(
          onScrollChanged: _onScrollChanged,
          key: _genreKey,
        ),
        FavoritesScreen(onScrollChanged: _onScrollChanged, key: _favoriteKey),
        // SettingsScreen(key: _settingsKey),
      ];

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

    _pageController.addListener(() {
      if (_isTapNavigating) return; // ★ ここが肝

      setState(() {
        _pageProgress = _pageController.page ?? _selectedIndex.toDouble();
      });
    });

    // 🔥 postFrameで確実にattach後に登録
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.position.isScrollingNotifier.addListener(() {
        final isScrolling = _pageController.position.isScrollingNotifier.value;

        if (isScrolling && _isScrollingDown) {
          setState(() {
            _isScrollingDown = false;
          });
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLatestVersion(context);
    });

    if (debugMode) {
      resetReviewDebugState();
    } else {
      // 👇 アプリ起動1回としてカウント
      incrementUsageCount();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final region = context.read<RegionProvider>().regionCode;

    logger.w("🚀 Prefetch trigger AFTER Region init: $region");

    _prefetchPopular(region);
  }

  Future<void> _prefetchPopular(String region) async {
    final api = context.read<YouTubeApiService>();

    await api.fetchPopularVideos(
      maxResults: 20,
      regionCode: region,
    );

    logger.i("🔥 Popular Prefetch DONE");
  }

  Future<void> resetReviewDebugState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('app_usage_count');
    await prefs.remove('review_requested_month');

    // もし他にもあれば追加
    // await prefs.remove('review_requested_version');

    debugPrint('🔧 Review debug state reset');
  }

  void showUpdateDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.updateNoticeTitle),
        content: Text(t.appUpdatedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onScrollChanged(bool isScrollingDown) {
    if (_isScrollingDown != isScrollingDown && mounted) {
      setState(() => _isScrollingDown = isScrollingDown);
    }
  }

  void _handleReselectTab(int index) {
    switch (index) {
      case 0:
        _topicKey.currentState?.scrollToTop();
        break;
      case 1:
        _popularKey.currentState?.scrollToTop();
        break;
      case 2:
        _genreKey.currentState?.scrollToTop();
        break;
      case 3:
        _favoriteKey.currentState?.scrollToTop();
        break;
      // case 4:
      //   _settingsKey.currentState?.scrollToTop();
      //   break;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text("Tube Plus"),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("設定"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapProvider>();
    final adsRemoved = iap.isPurchased(IapProducts.removeAds.id);

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final bool shouldShowBanner =
            iap.isReady && (!adsRemoved) && (!isKeyboardVisible);

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(),
          extendBody: true,
          body: Stack(
            children: [
              // メイン画面（全面）
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (_selectedIndex == index) return;

                    setState(() => _selectedIndex = index);
                  },
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
                    child: TopBar(
                      key: _topBarKey,
                      mode: TopBarMode.tabs,
                      selectedIndex: _selectedIndex,
                      pageProgress: _pageProgress,
                      isTapNavigating: _isTapNavigating,
                      onMenuTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      onTabSelected: (index) {
                        Feedback.forTap(context);

                        // ==================================================
                        // 🔥 同じタブ → スクロールTOP
                        // ==================================================
                        if (_selectedIndex == index) {
                          _handleReselectTab(index);
                          return;
                        }

                        // ==================================================
                        // 🔥 別タブ → 通常遷移
                        // ==================================================
                        setState(() {
                          _isTapNavigating = true;
                          _selectedIndex = index;
                          _pageProgress = index.toDouble();
                        });

                        _pageController.jumpToPage(index);

                        if (mounted) {
                          setState(() {
                            _isTapNavigating = false;
                            _pageProgress = index.toDouble();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),

              // ★ バナー広告（先に描画）
              if (shouldShowBanner)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AdBanner(isMain: true),
                ),
            ],
          ),
        );
      },
    );
  }
}
