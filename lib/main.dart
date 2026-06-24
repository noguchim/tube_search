// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/providers/density_provider.dart';
import 'package:tube_search/providers/iap_provider.dart';
import 'package:tube_search/providers/pickup_settings_provider.dart';
import 'package:tube_search/providers/push_notification_provider.dart';
import 'package:tube_search/providers/push_subscription_provider.dart';
import 'package:tube_search/providers/recommendation_history_provider.dart';
import 'package:tube_search/providers/region_provider.dart';
import 'package:tube_search/providers/search_ui_provider.dart';
import 'package:tube_search/providers/settings_provider.dart';
import 'package:tube_search/screens/settings_drawer.dart';
import 'package:tube_search/screens/topic_screen.dart';
import 'package:tube_search/screens/video_detail_screen.dart';
import 'package:tube_search/services/device_id_store.dart';
import 'package:tube_search/services/expanded_video_controller.dart';
import 'package:tube_search/services/iap_products.dart';
import 'package:tube_search/services/iap_service.dart';
import 'package:tube_search/services/limit_service.dart';
import 'package:tube_search/services/push_navigation_overlay.dart';
import 'package:tube_search/services/push_token_store.dart';
import 'package:tube_search/services/watch_history_service.dart';
import 'package:tube_search/services/youtube_api_service.dart';
import 'package:tube_search/theme/app_theme.dart';
import 'package:tube_search/utils/app_logger.dart';
import 'package:tube_search/utils/app_version.dart';
import 'package:tube_search/utils/navigator_key.dart';
import 'package:tube_search/utils/request_review.dart';
import 'package:tube_search/widgets/ad_banner.dart';
import 'package:tube_search/widgets/consent_manager.dart';
import 'package:tube_search/widgets/search_overlay.dart';
import 'package:tube_search/widgets/top_bar.dart';
import 'package:tube_search/widgets/trend_word_sheet.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/favorites_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/popular_videos_screen.dart';
import 'services/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final messaging = FirebaseMessaging.instance;

  // 通知許可（1回でOK）
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

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

        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => PushNotificationProvider()..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => WatchHistoryService()..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => SearchUIProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => PushSubscriptionProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => PickupSettingsProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => RecommendationHistoryProvider()..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => PushNavigationOverlay(),
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
      child: MyApp(initialMessage: initialMessage),
    ),
  );
}

class MyApp extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const MyApp({super.key, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<String>? _tokenRefreshSub;
  RegionProvider? _regionProvider;

  int _notificationIdFromVideoId(String videoId) {
    return videoId.hashCode & 0x7fffffff;
  }

  List<String> _parsePickupKeys(dynamic raw) {
    if (raw == null) return const [];

    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return const [];

    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Fallback to single key below.
    }

    return [text];
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final regionProvider = context.read<RegionProvider>();
      _regionProvider = regionProvider;
      regionProvider.addListener(_handleRegionChanged);
      unawaited(regionProvider.initFromLocale());
    });

    // 🔥 初回フレーム後にGDPR実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConsent();
    });

    // FCM + ローカル通知初期化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final regionProvider = context.read<RegionProvider>();
      final api = context.read<YouTubeApiService>();

      // 先にローカル通知を初期化
      await initLocalNotification();

      if (!mounted) return;

      await regionProvider.initFromLocale();

      if (!mounted) return;

      await _initFcm(api);

      // 完全終了 → 通知タップ起動
      if (widget.initialMessage != null) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () async {
            if (!mounted) return;
            await handlePushNavigation(widget.initialMessage!);
          },
        );
      }
    });

    // 通常タップ（OK）
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      logger.w("🔥 TAP message: ${message.data}");
      handlePushNavigation(message);
    });
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    _regionProvider?.removeListener(_handleRegionChanged);
    super.dispose();
  }

  Future<void> _handleRegionChanged() async {
    if (!mounted) return;

    try {
      final regionProvider = _regionProvider;
      if (regionProvider == null) return;
      final api = context.read<YouTubeApiService>();

      final token = await PushTokenStore.getToken();
      if (token == null || token.isEmpty) return;

      final deviceId = await DeviceIdStore.getOrCreate();
      final regionCode = regionProvider.regionCode;

      await api.saveFcmToken(
        token,
        regionCode,
        deviceId,
      );

      logger.i("✅ FCM token region synced: $regionCode");
    } catch (e, st) {
      logger.e("❌ region sync saveFcmToken error: $e", stackTrace: st);
    }
  }

  Future<void> _initConsent() async {
    await ConsentManager.requestConsent();
  }

  Future<Uint8List> _downloadImageWithFallback(String? url) async {
    try {
      if (url == null || url.isEmpty) throw Exception("empty url");

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }

      throw Exception("download failed");
    } catch (e) {
      // 🔥 フォールバック
      final byteData = await rootBundle.load('assets/images/no_image.png');

      return byteData.buffer.asUint8List();
    }
  }

  Future<void> _initFcm(YouTubeApiService api) async {
    final messaging = FirebaseMessaging.instance;
    final regionProvider = context.read<RegionProvider>();
    final pushSubscriptions = context.read<PushSubscriptionProvider>();
    final regionCode = regionProvider.regionCode;

    final token = await _getFcmToken(messaging);
    logger.i("🔥 TOKEN: $token");
    final deviceId = await DeviceIdStore.getOrCreate();
    final storedToken = await PushTokenStore.getToken();
    final isFreshLocalInstall = storedToken == null || storedToken.isEmpty;

    if (token != null && token.isNotEmpty) {
      final nav = rootNavigatorKey.currentState;

      if (nav == null) {
        logger.w("❌ navigator null");
        return;
      }

      await PushTokenStore.save(token);
      await api.saveFcmToken(
        token,
        regionCode,
        deviceId,
      );

      if (!mounted) return;

      if (isFreshLocalInstall) {
        await api.replacePushSubscriptions(
          token: token,
          items: const [],
          resetSentLogs: true,
        );

        if (!mounted) return;

        pushSubscriptions.setEnabledKeys(const []);
        logger.i("✅ Push subscriptions reset for fresh install");
      } else {
        await _preloadPushSubscriptions(api, token);
      }
    }

    FirebaseMessaging.onMessage.listen((message) {
      logger.i("🔥 RAW message: ${message.data}");
      logger.i("🔥 notification: ${message.notification?.title}");

      final type = message.data['type']?.toString() ?? '';
      final title = message.data['title'] ?? message.notification?.title;
      final body = message.data['body'] ?? message.notification?.body;

      if (title == null || body == null) return;

      final image = message.data['image'];
      final videoId = message.data['videoId']?.toString() ?? '';
      final pickupKey = message.data['pickupKey']?.toString() ?? '';
      final pickupKeys = _parsePickupKeys(message.data['pickupKeys']);

      if (Platform.isIOS) return;

      showLocalNotification(
        type,
        title,
        body,
        image,
        videoId,
        pickupKey,
        pickupKeys,
      );
    });

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        try {
          logger.i("🔥 TOKEN REFRESH: $newToken");

          final regionCode = regionProvider.regionCode;

          await PushTokenStore.save(newToken);

          await api.saveFcmToken(
            newToken,
            regionCode,
            deviceId,
          );

          final keys = await api.fetchPushSubscriptionKeys(
            token: newToken,
          );

          if (!mounted) return;

          pushSubscriptions.setEnabledKeys(keys);

          logger.i("✅ Push subscriptions refreshed count=${keys.length}");
        } catch (e, st) {
          logger.e("❌ token refresh subscription preload error: $e",
              stackTrace: st);
        }
      },
    );
  }

  Future<String?> _getFcmToken(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      String? apnsToken;

      for (var attempt = 0; attempt < 10; attempt++) {
        apnsToken = await messaging.getAPNSToken();
        logger.i("🍎 APNs TOKEN: $apnsToken");

        if (apnsToken != null && apnsToken.isNotEmpty) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (apnsToken == null || apnsToken.isEmpty) {
        logger.w("❌ APNs token not ready");
        return null;
      }
    }

    try {
      return await messaging.getToken();
    } catch (e, st) {
      logger.e("❌ FCM token error: $e", stackTrace: st);
      return null;
    }
  }

  Future<void> _preloadPushSubscriptions(
    YouTubeApiService api,
    String token,
  ) async {
    try {
      final keys = await api.fetchPushSubscriptionKeys(
        token: token,
      );

      if (!mounted) return;

      context.read<PushSubscriptionProvider>().setEnabledKeys(keys);

      logger.i("✅ Push subscriptions preloaded count=${keys.length}");
    } catch (e, st) {
      logger.e("❌ Push subscriptions preload error: $e", stackTrace: st);
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initLocalNotification() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    const channel = AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'General notifications',
      importance: Importance.high,
    );

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // Android 13+ 対応
    await androidPlugin?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload != null && payload.isNotEmpty) {
          handleLocalNotificationTap(payload);
        }
      },
    );
  }

  void handleLocalNotificationTap(String payload) async {
    final data = jsonDecode(payload);

    final type = data['type']?.toString() ?? '';
    final videoId = data['videoId']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';

    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      logger.w("❌ navigator null");
      return;
    }

    final context = nav.context;

    if (type == 'pickup_new') {
      final pickupKey = data['pickupKey']?.toString() ?? '';
      final pickupKeys = _parsePickupKeys(data['pickupKeys']);
      final videoId = data['videoId']?.toString() ?? '';

      nav.popUntil((route) => route.isFirst);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = rootNavigatorKey.currentState;
        if (nav == null) return;

        nav.context.read<PickupSettingsProvider>().openFromPush(
              pickupKey: pickupKey,
              videoId: videoId,
              pickupKeys: pickupKeys,
            );
      });

      return;
    }

    if (videoId.isEmpty) {
      logger.w("❌ local push: videoId empty payload=$payload");
      return;
    }

    final api = context.read<YouTubeApiService>();
    final video = await api.fetchVideoById(videoId);
    if (video == null) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => VideoDetailScreen(
          video: video,
          title: title,
        ),
      ),
    );
  }

  Future<void> showLocalNotification(
    String type,
    String title,
    String body,
    String? imageUrl,
    String videoId,
    String pickupKey,
    List<String> pickupKeys,
  ) async {
    final imageBytes = await _downloadImageWithFallback(imageUrl);

    final bigPictureStyle = BigPictureStyleInformation(
      ByteArrayAndroidBitmap(imageBytes),
      contentTitle: "<b>$title</b>",
      summaryText: body,
      htmlFormatContentTitle: true,
      htmlFormatSummaryText: true,
    );

    final android = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigPictureStyle,
    );

    final details = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(
      _notificationIdFromVideoId(videoId),
      title,
      body,
      details,
      payload: jsonEncode({
        "type": type,
        "videoId": videoId,
        "pickupKey": pickupKey,
        "pickupKeys": pickupKeys,
        "title": title,
        "body": body,
      }),
    );
  }

  bool _isPushingFromPush = false;

  Future<void> handlePushNavigation(RemoteMessage message) async {
    if (_isPushingFromPush) return;
    _isPushingFromPush = true;

    try {
      final type = message.data['type']?.toString() ?? '';
      final videoId = message.data['videoId']?.toString() ?? '';

      logger.w("🚨 PUSH TAP type=$type videoId=$videoId");
      logger.w("nav=${rootNavigatorKey.currentState}");

      final nav = rootNavigatorKey.currentState;

      if (nav == null) {
        logger.w("❌ navigator null");
        return;
      }

      final context = nav.context;
      final pushOverlay = context.read<PushNavigationOverlay>();

      // =====================================================
      // 新着通知：動画詳細へ直行せず、ホームのピックアップへ
      // =====================================================
      if (type == 'pickup_new') {
        final pickupKey = message.data['pickupKey']?.toString() ?? '';
        final pickupKeys = _parsePickupKeys(message.data['pickupKeys']);
        final videoId = message.data['videoId']?.toString() ?? '';

        nav.popUntil((route) => route.isFirst);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = rootNavigatorKey.currentState;
          if (nav == null) return;

          nav.context.read<PickupSettingsProvider>().openFromPush(
                pickupKey: pickupKey,
                videoId: videoId,
                pickupKeys: pickupKeys,
              );
        });

        return;
      }

      logger.w("🚨 PUSH ROUTE: video detail");

      // =====================================================
      // 人気急上昇など：従来通り動画詳細へ
      // =====================================================
      nav.popUntil((route) => route.isFirst);
      pushOverlay.show();

      if (videoId.isEmpty) {
        logger.w("❌ push: videoId empty");
        return;
      }

      final api = context.read<YouTubeApiService>();
      final video = await api.fetchVideoById(videoId);

      if (video == null) {
        logger.w("❌ push: video not found");
        return;
      }

      final title = message.data['title']?.toString() ?? '';

      nav.push(
        MaterialPageRoute(
          builder: (_) => VideoDetailScreen(
            video: video,
            title: title,
          ),
        ),
      );
    } catch (e, st) {
      logger.e("❌ push navigation error: $e", stackTrace: st);
    } finally {
      rootNavigatorKey.currentContext?.read<PushNavigationOverlay>().hide();
      _isPushingFromPush = false;
    }
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
      title: 'Tube+',

      // 🍀 Light / Dark テーマを適用
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeProvider.themeMode,
      // ← Provider で切替
      builder: (context, child) {
        final visible = context.watch<PushNavigationOverlay>().visible;
        return Stack(
          children: [
            if (child != null) child,
            if (visible)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.22),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },

      home: const MainNavigationScreen(),
      navigatorKey: rootNavigatorKey,
    );
  }
}

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
    final iap = context.read<IapProvider>();
    final limit = LimitService.videoListLimit(iap);

    try {
      final list = await api.fetchPopularVideos(
        regionCode: region,
        hours: 12,
        maxResults: limit,
      );

      logger.i("🔥 Popular Prefetch DONE count=${list.length}");
    } catch (e, st) {
      logger.e("❌ Popular Prefetch ERROR: $e", stackTrace: st);
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapProvider>();
    final adsRemoved = iap.isPurchased(IapProducts.removeAds.id);
    final search = context.watch<SearchUIProvider>();
    final expandedController = context.read<ExpandedVideoController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final bool shouldShowBanner =
            iap.isReady && (!adsRemoved) && (!isKeyboardVisible);

        return Scaffold(
          key: _scaffoldKey,
          drawer: const SettingsDrawer(),
          drawerScrimColor: isDark
              ? Colors.black.withValues(alpha: 0.54)
              : Colors.black.withValues(alpha: 0.12),
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
                    expandedController.close();
                    context.read<SearchUIProvider>().close();
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
                      onTrendTap: () {
                        expandedController.close();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const TrendWordSheet(),
                        );
                      },
                      onSearchTap: () {
                        expandedController.close();
                        context.read<SearchUIProvider>().open();
                      },
                      onTabSelected: (index) {
                        Feedback.forTap(context);

                        // 🔥 キーボード・Focusを先に確実に解除
                        FocusManager.instance.primaryFocus?.unfocus();

                        // 🔥 検索Overlayを閉じる
                        context.read<SearchUIProvider>().close();
                        expandedController.close();

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

              if (search.isOpen)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: 1,
                    child: SearchOverlay(
                      isOpen: true,
                      onClose: () => search.close(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
