import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';

import '../providers/banner_ad_provider.dart';
import '../providers/density_provider.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/card_density_prefs.dart';
import '../widgets/ad_banner.dart';
import '../widgets/density_fab.dart';
import '../widgets/expanded_video_overlay.dart';

import '../widgets/network_error_view.dart';
import '../widgets/popular_big_section.dart';
import '../widgets/popular_middle_section.dart';
import '../widgets/popular_small_section.dart';
import '../widgets/top_bar_back.dart';

class GenreVideosScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  final String? keyword;
  final ValueChanged<bool>? onScrollChanged;

  const GenreVideosScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    this.keyword,
    this.onScrollChanged,
  });

  @override
  State<GenreVideosScreen> createState() => _GenreVideosScreenState();
}

class _GenreVideosScreenState extends State<GenreVideosScreen> {
  final YouTubeApiService _apiService = YouTubeApiService();
  late Future<List<Map<String, dynamic>>> _futureVideos;
  final ScrollController _scrollController = ScrollController();

  int _lastLimit = 20;

  bool _isSearching = false;
  Completer<List<Map<String, dynamic>>>? _activeRequest;
  bool _showTopBar = true;

  @override
  void initState() {
    super.initState();
    _futureVideos = _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final iap = context.watch<IapProvider>();
    final currentLimit = LimitService.videoListLimit(iap);

    if (currentLimit != _lastLimit) {
      _lastLimit = currentLimit;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _futureVideos = _loadVideos(forceRefresh: true));
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // 🔥 スクロール方向チェック
  // ---------------------------------------------------------
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final d = _scrollController.position.userScrollDirection;

    if (d == ScrollDirection.reverse && _showTopBar) {
      setState(() => _showTopBar = false);
    } else if (d == ScrollDirection.forward && !_showTopBar) {
      setState(() => _showTopBar = true);
    }
  }

  String shortTitle(String t) => t.length > 12 ? '${t.substring(0, 12)}…' : t;

  // ---------------------------------------------------------
  // 🔥 API 統合フェッチ（キーワード or 人気ジャンル）
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadVideos({bool forceRefresh = false}) {
    // ✅ すでに検索中 → 同じFutureを返して二重実行を防ぐ
    if (_isSearching && _activeRequest != null) {
      return _activeRequest!.future;
    }

    _isSearching = true;
    _activeRequest = Completer<List<Map<String, dynamic>>>();

    () async {
      final kw = widget.keyword?.trim();
      final cat = widget.categoryId == "0" ? "" : widget.categoryId;

      final iap = context.read<IapProvider>();
      final limit = LimitService.videoListLimit(iap);

      List<Map<String, dynamic>> videos = [];

      logger.w("🧮 limit=$limit (IAP purchased=${iap.isPurchased})");




      try {
        logger.i("🎯 loadVideos: kw=${kw ?? '(null)'} / cat=$cat");

        if (kw != null && kw.isNotEmpty) {
          // キーワード検索

          logger.i("🔎 mode=keywordSearch");

          final region = context.read<RegionProvider>().regionCode;

          var search = await _apiService.searchWithStats(
            categoryId: cat,
            keyword: kw,
            maxResults: limit,
            regionCode: region,
            forceRefresh: forceRefresh,
          );

          logger.w("📌 [kw]searchCount=${search.length}");

          // 0件ならカテゴリ無しでフォールバック
          if (search.isEmpty && cat.isNotEmpty) {
            search = await _apiService.searchWithStats(
              categoryId: "",
              keyword: kw,
              maxResults: limit,
              regionCode: region,
              forceRefresh: forceRefresh,
            );
          }

          if (search.isEmpty) {
            _activeRequest?.complete([]);
            return;
          }

          final ids = search.map((v) => v.id).join(',');
          logger.w("📌 [kw]idsCount=${ids.split(',').length}");
          final detail = await _apiService.fetchVideosByIds(ids);

          videos = detail
              .map((v) => {
            'id': v.id,
            'title': v.title,
            'thumbnailUrl': v.thumbnailUrl,
            'channelTitle': v.channelTitle,
            'publishedAt': v.publishedAt?.toIso8601String(),
            'viewCount': v.viewCount ?? 0,
            'durationSeconds': v.durationSeconds ?? 0,
          })
              .toList();

          logger.w("📌 [kw]detailCount=${detail.length}");
        } else {
          // 人気ジャンル一覧

          logger.i("🔥 mode=popularGenreList");

          final region = context.read<RegionProvider>().regionCode;

          final list = await _apiService.fetchPopularVideos(
            videoCategoryId: cat,
            maxResults: limit,
            regionCode: region,
            forceRefresh: forceRefresh,
          );

          videos = list
              .map((v) => {
            'id': v.id,
            'title': v.title,
            'thumbnailUrl': v.thumbnailUrl,
            'channelTitle': v.channelTitle,
            'publishedAt': v.publishedAt?.toIso8601String(),
            'viewCount': v.viewCount ?? 0,
            'durationSeconds': v.durationSeconds ?? 0,
          })
              .toList();

          logger.w("📌 [gr]listCount=${list.length}");
        }

        // ソート & 更新時間
        videos.sort(
              (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int),
        );

        videos = videos.take(limit).toList();

        _activeRequest?.complete(videos);

      } catch (e, st) {
        // ✅ FutureBuilderに伝播できるようエラーもcompleteError
        if (!(_activeRequest?.isCompleted ?? true)) {
          _activeRequest?.completeError(e, st);
        }
      } finally {
        _isSearching = false;
        _activeRequest = null;
      }
    }();

    return _activeRequest!.future;
  }

  // ---------------------------------------------------------
  // 🔥 Pull-to-refresh（setState は同期のみ）
  // ---------------------------------------------------------
  Future<void> _refreshVideos() async {
    if (_isSearching) return; // ✅ 追加

    try {
      final data = await _loadVideos(forceRefresh: true); // ✅ refreshは強制fresh推奨
      if (!mounted) return;

      setState(() {
        _futureVideos = Future.value(data);
      });
    } catch (e) {
      if (!mounted) return;
      rethrow;
    }
  }

  Widget _densityControl(List<Map<String, dynamic>> videos) {
    final density = context.watch<DensityProvider>().density;

    switch (density) {
      case CardDensity.big:
        return PopularBigSection(videos: videos);

      case CardDensity.middle:
        return PopularMiddleSection(videos: videos);

      case CardDensity.small:
        return PopularSmallSection(videos: videos);
    }
  }

  // ---------------------------------------------------------
  // 🔥 UI 本体
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final String topTitle =
    (widget.keyword != null && widget.keyword!.isNotEmpty)
        ? widget.keyword!
        : widget.categoryTitle;
    final expanded = context.watch<ExpandedVideoController>();

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    final density = context.watch<DensityProvider>().density;

    final bannerLoaded = context.watch<BannerAdProvider>().isLoaded;
    final adsRemoved =
    context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);
    final bool shouldShowBanner =
        (!adsRemoved) && bannerLoaded;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45), // ← AdMob分持ち上げ
        child: DensityFab(
          density: density,
          onToggle: () => context.read<DensityProvider>().toggle(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Stack(
        children: [
          // =============================
          // 背面：FutureBuilder + Scroll
          // =============================
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureVideos,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return NetworkErrorView(
                  onRetry: () {
                    setState(() {
                      _futureVideos = _loadVideos(forceRefresh: true);
                    });
                  },
                );
              }

              final videos = snap.data ?? [];

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshVideos,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 55 + MediaQuery.of(context).padding.top,
                          ),
                        ),

                        _densityControl(videos),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 70),
                        ),
                      ],
                    ),
                  ),

                  // Expanded Overlay
                  if (expanded.video != null)
                    Positioned.fill(
                      child: ExpandedVideoOverlay(
                        video: expanded.video!,
                        rank: expanded.rank!,
                        onClose: () {
                          context.read<ExpandedVideoController>().close();
                        },
                      ),
                    ),
                ],
              );
            },
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

          // =============================
          // 🧭 TopBar（最前面・固定）
          // =============================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _showTopBar ? Offset.zero : const Offset(0, -1.1),
              child: TopBarBack(
                title: topTitle,
                onBack: Navigator.of(context).pop,
              ),
            ),
          ),
        ],
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
