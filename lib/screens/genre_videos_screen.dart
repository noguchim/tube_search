import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../providers/density_provider.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/card_density_prefs.dart';
import '../utils/ui_spacing.dart';
import '../widgets/ad_banner.dart';
import '../widgets/density_fab.dart';
import '../widgets/empty_result_view.dart';
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
  final String searchMode;
  final ValueChanged<bool>? onScrollChanged;

  const GenreVideosScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    this.keyword,
    required this.searchMode,
    this.onScrollChanged,
  });

  @override
  State<GenreVideosScreen> createState() => _GenreVideosScreenState();
}

class _GenreVideosScreenState extends State<GenreVideosScreen> {
  late Future<List<YouTubeVideo>> _futureVideos;
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
  Future<List<YouTubeVideo>> _loadVideos({bool forceRefresh = false}) async {
    final kw = widget.keyword?.trim();
    final cat = widget.categoryId == "0" ? "" : widget.categoryId;

    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();
    final iap = context.read<IapProvider>();

    final limit = LimitService.videoListLimit(iap);

    if (kw != null && kw.isNotEmpty) {
      var search = await api.searchWithStats(
        categoryId: cat,
        keyword: kw,
        searchMode: widget.searchMode,
        maxResults: limit,
        regionCode: region,
        forceRefresh: forceRefresh,
      );

      if (search.isEmpty && cat.isNotEmpty) {
        search = await api.searchWithStats(
          categoryId: "",
          keyword: kw,
          searchMode: widget.searchMode,
          maxResults: limit,
          regionCode: region,
          forceRefresh: forceRefresh,
        );
      }

      return search.take(limit).toList();
    }

    return api.fetchPopularVideos(
      videoCategoryId: cat,
      maxResults: limit,
      regionCode: region,
      forceRefresh: forceRefresh,
    );
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

  Widget _densityControl(List<YouTubeVideo> videos) {
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
    final String topTitle = (widget.categoryTitle.isNotEmpty)
        ? widget.categoryTitle
        : (widget.keyword ?? "");
    final expanded = context.watch<ExpandedVideoController>();

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    final density = context.watch<DensityProvider>().density;

    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);
    final bool shouldShowBanner = !adsRemoved;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: adsRemoved ? 15 : 45), // ← AdMob分持ち上げ
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
          FutureBuilder<List<YouTubeVideo>>(
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

              // ★ 0件表示
              if (videos.isEmpty) {
                return EmptyResultView(
                  onRetry: () {
                    setState(() {
                      _futureVideos = _loadVideos(forceRefresh: true);
                    });
                  },
                );
              }

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
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: UISpacing.bottomSpacer(
                              context,
                              hasFab: true,
                              hasAd: !adsRemoved,
                            ),
                          ),
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
