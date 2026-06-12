import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/density_provider.dart';
import '../providers/iap_provider.dart';
import '../providers/recommendation_history_provider.dart';
import '../providers/region_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/card_density_prefs.dart';
import '../utils/ui_spacing.dart';
import 'anime_webview_screen.dart';
import '../widgets/ad_banner.dart';
import '../widgets/density_fab.dart';
import '../widgets/empty_result_view.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/network_error_view.dart';
import '../widgets/section_big.dart';
import '../widgets/section_middle.dart';
import '../widgets/section_side.dart';
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

  final bool _isSearching = false;
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

    if (widget.categoryId == "-1") {
      final history = context.read<RecommendationHistoryProvider>();
      await history.load();

      final signals = await history.topSignalsForRecommendation(limit: 8);

      if (signals.isEmpty) {
        final allData = await api.fetchPickupAll(
          regionCode: region,
          forceRefresh: forceRefresh,
        );
        list = allData['recommended'] ?? allData['all'] ?? [];
        return _applySort(list.take(limit).toList());
      }

      final excludeTargets = await history.pickupExcludeTargets();

      list = await api.fetchRecommendedVideos(
        signals: signals,
        excludeChannelIds: excludeTargets.channelIds,
        excludeCategoryIds: excludeTargets.categoryIds,
        maxResults: limit,
        regionCode: region,
        forceRefresh: forceRefresh,
      );

      return _applySort(list.take(limit).toList());
    }

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

  bool _shouldShowAnimeLinks(String regionCode) {
    final region = regionCode.toUpperCase();
    return widget.categoryId == "31" && (region == "JP" || region == "EN");
  }

  String _animeCurrentSeasonUrl(String regionCode, {DateTime? now}) {
    final baseDate = now ?? DateTime.now();
    final year = baseDate.year;
    final season = switch (baseDate.month) {
      >= 1 && <= 3 => "winter",
      >= 4 && <= 6 => "spring",
      >= 7 && <= 9 => "summer",
      _ => "autumn",
    };

    if (regionCode.toUpperCase() == "EN") {
      final liveChartSeason = season == "autumn" ? "fall" : season;
      return "https://www.livechart.me/$liveChartSeason-$year/tv";
    }

    return "https://anime.nicovideo.jp/period/$year-$season.html?from=nanime_period_list";
  }

  String _animePastSeasonsUrl(String regionCode) {
    if (regionCode.toUpperCase() == "EN") {
      return "https://www.livechart.me/charts";
    }

    return "https://anime.nicovideo.jp/period/";
  }

  void _openAnimeLink({
    required String url,
    required String title,
  }) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.animeLinkPending),
        ),
      );
      return;
    }

    logger.i("[Anime link] $url");

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimeWebViewScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  Widget _buildAnimeLinksContainer(String regionCode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202020) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _AnimeLinkRow(
              label: l.animeCurrentSeasonLink,
              onTap: () => _openAnimeLink(
                url: _animeCurrentSeasonUrl(regionCode),
                title: l.animeCurrentSeasonTitle,
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            _AnimeLinkRow(
              label: l.animePastSeasonsLink,
              onTap: () => _openAnimeLink(
                url: _animePastSeasonsUrl(regionCode),
                title: l.animePastSeasonsLink,
              ),
            ),
          ],
        ),
      ),
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
        return SectionBig(videos: videos);

      case CardDensity.side:
        return SectionSide(videos: videos);

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
    final regionCode = context.watch<RegionProvider>().regionCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: expanded.video == null
          ? Padding(
              padding:
                  EdgeInsets.only(bottom: adsRemoved ? 15 : 45), // ← AdMob分持ち上げ
              child: DensityFab(
                density: density,
                onToggle: () => context.read<DensityProvider>().toggle(),
              ),
            )
          : null,
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
                        if (_shouldShowAnimeLinks(regionCode))
                          SliverToBoxAdapter(
                            child: _buildAnimeLinksContainer(regionCode),
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

class _AnimeLinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimeLinkRow({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
