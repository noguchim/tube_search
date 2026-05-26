import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/youtube_video.dart';
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
import '../utils/ui_spacing.dart';
import '../widgets/ad_banner.dart';
import '../widgets/density_fab.dart';
import '../widgets/empty_result_view.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/network_error_view.dart';
import '../widgets/section_big.dart';
import '../widgets/section_middle.dart';
import '../widgets/section_small.dart';
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
  bool _showTopBar = true;
  String _sort = "score";

  @override
  void initState() {
    super.initState();
    _loadSort();
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

  Future<List<YouTubeVideo>> _loadVideos({bool forceRefresh = false}) async {
    final kw = widget.keyword?.trim();
    final cat = widget.categoryId == "0" ? "" : widget.categoryId;

    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();
    final iap = context.read<IapProvider>();

    final limit = LimitService.videoListLimit(iap);

    final mode = widget.searchMode;
    logger.i(
        "[_loadVideos]query=$kw mode=$mode max=$limit region=$region categoryId=$cat");

    List<YouTubeVideo> list = [];

    // 通常検索
    if (kw != null && kw.isNotEmpty) {
      list = await api.searchWithStats(
        categoryId: cat,
        keyword: kw,
        searchMode: widget.searchMode,
        maxResults: limit,
        regionCode: region,
        forceRefresh: forceRefresh,
      );

      if (list.isEmpty && cat.isNotEmpty) {
        list = await api.searchWithStats(
          categoryId: "",
          keyword: kw,
          searchMode: widget.searchMode,
          maxResults: limit,
          regionCode: region,
          forceRefresh: forceRefresh,
        );
      }

      final result = list.take(limit).toList();
      return _applySort(result);
    }

    return [];
  }

  Future<void> _loadSort() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("sort_genre") ?? "score";

    if (!mounted) return;

    setState(() {
      _sort = saved;
    });
  }

  Future<void> _saveSort(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("sort_genre", value);
  }

  List<YouTubeVideo> _applySort(List<YouTubeVideo> list) {
    switch (_sort) {
      case "views":
        list.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
        for (int i = 0; i < list.length; i++) {
          final v = list[i];
          final formattedDate = v.publishedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(v.publishedAt!)
              : "-";

          logger.i(
            "[$i] "
            "${v.score?.toStringAsFixed(2)} "
            "${v.viewCount} "
            "$formattedDate "
            "${_short(v.title)}",
          );
        }
        break;

      case "date":
        list.sort((a, b) => (b.publishedAt ?? DateTime(0))
            .compareTo(a.publishedAt ?? DateTime(0)));
        for (int i = 0; i < list.length; i++) {
          final v = list[i];
          final formattedDate = v.publishedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(v.publishedAt!)
              : "-";

          logger.i(
            "[$i] "
            "${v.score?.toStringAsFixed(2)} "
            "${v.viewCount} "
            "$formattedDate "
            "${_short(v.title)}",
          );
        }
        break;

      case "score":
      default:
        list.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
        for (int i = 0; i < list.length; i++) {
          final v = list[i];
          final formattedDate = v.publishedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(v.publishedAt!)
              : "-";

          logger.i(
            "[$i] "
            "${v.score?.toStringAsFixed(2)} "
            "${v.viewCount} "
            "$formattedDate "
            "${_short(v.title)}",
          );
        }
    }

    return list;
  }

  String _short(String s, [int max = 50]) {
    if (s.length <= max) return s;
    return "${s.substring(0, max)}...";
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
        return SectionBig(videos: videos);

      case CardDensity.middle:
        return SectionMiddle(videos: videos);

      case CardDensity.small:
        return SectionSmall(videos: videos);
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
    final controller = context.read<ExpandedVideoController>();

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
                logger.e("❌ FutureBuilder error: ${snap.error}");
                logger.e("❌ StackTrace: ${snap.stackTrace}");

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
                          controller.close();
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
              child: AdBanner(isMain: false),
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
                currentSort: _sort,
                onBack: Navigator.of(context).pop,
                onSortSelected: (value) async {
                  setState(() {
                    _sort = value;
                    _futureVideos = _loadVideos(forceRefresh: true);
                  });
                  await _saveSort(value); // 🔥 追加
                },
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
