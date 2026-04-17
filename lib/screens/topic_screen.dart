// lib/screens/genre_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/trending_keyword.dart';
import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/ui_spacing.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_list_topic.dart';
import 'genre_videos_screen.dart';

int _selectedIndex = 0;
Map<String, List<YouTubeVideo>> cache = {};
Map<String, DateTime> cacheTime = {};

final List<Map<String, String>> _genres = [
  {"label": "音楽トレンド", "keyword": "Music"},
  {"label": "ゲーム", "keyword": "ゲーム"},
  {"label": "ユーチューバー", "keyword": "ユーチューバー"},
];

class TopicScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const TopicScreen({super.key, this.onScrollChanged});

  @override
  State<TopicScreen> createState() => TopicScreenState();
}

class TopicScreenState extends State<TopicScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String _lastRegion = "JP";
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _networkError = false;

  Timer? _debounce;
  bool _isScrollingDown = false;

  late AnimationController _tapAnim;

  bool _didInitialJump = false;

  List<TrendingKeyword> _trending = [];
  bool _trendingLoaded = false;
  bool _showAllTrending = false;
  String _trendingTimestamp = "";
  double _lastOffset = 0;

  void scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // _scrollController.addListener(_handleScroll);

    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialJump) return;
    _didInitialJump = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();

    // ① キャッシュ即表示
    final cached = api.getCachedTrending(
      regionCode: region,
      max: 10,
    );

    if (cached.isNotEmpty) {
      setState(() {
        _trending = cached;
        _trendingLoaded = true;
        _trendingTimestamp = _buildTrendingNow();
      });
      return;
    }

    // ② なければfetch
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    setState(() {
      _trendingLoaded = false;
    });

    try {
      final api = context.read<YouTubeApiService>();

      final result = await api.fetchTrendingKeywords(
        regionCode: context.read<RegionProvider>().regionCode,
        max: 10,
      );

      if (!mounted) return;

      setState(() {
        _trending = result;
        _trendingLoaded = true;
        _trendingTimestamp = _buildTrendingNow();
      });
    } catch (e) {
      logger.e("Trending fetch error: $e");

      if (!mounted) return;

      setState(() {
        _trending = [];
        _trendingLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tapAnim.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // 🔥 スクロール方向通知
  // ----------------------------------------------------
  // void _handleScroll() {
  //   if (!_scrollController.hasClients) return;
  //
  //   final offset = _scrollController.offset;
  //
  //   // 🔥 トップ付近は常に表示（最重要）
  //   if (offset <= 10) {
  //     if (_isScrollingDown) {
  //       _isScrollingDown = false;
  //       widget.onScrollChanged?.call(false);
  //     }
  //     _lastOffset = offset;
  //     return;
  //   }
  //
  //   final delta = offset - _lastOffset;
  //
  //   // 🔽 下スクロール（ある程度動いた時だけ）
  //   if (delta > 5) {
  //     if (!_isScrollingDown) {
  //       _isScrollingDown = true;
  //       widget.onScrollChanged?.call(true);
  //     }
  //   }
  //
  //   // 🔼 上スクロール
  //   else if (delta < -5) {
  //     if (_isScrollingDown) {
  //       _isScrollingDown = false;
  //       widget.onScrollChanged?.call(false);
  //     }
  //   }
  //
  //   _lastOffset = offset;
  // }

  String _buildTrendingNow() {
    final now = DateTime.now();

    String two(int n) => n.toString().padLeft(2, '0');

    final date = "${now.month}/${now.day}";
    final time = "${two(now.hour)}:${two(now.minute)}";

    return "$date $time updated";
  }

  Widget _buildTrendingChips(ThemeData theme) {
    logger.i(
        "TrendTips start _trendingLoaded=$_trendingLoaded _trending=${_trending.map((e) => e.keyword).toList()}");

    if (!_trendingLoaded) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trending.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text("No Trends")),
      );
    }

    final Color toggleColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;

          double usedWidth = 0;
          final List<TrendingKeyword> oneLine = [];

          for (final t in _trending) {
            final keyword = t.keyword.trim();
            if (keyword.isEmpty) continue;

            final textPainter = TextPainter(
              text: TextSpan(
                text: keyword,
                style: const TextStyle(fontSize: 14),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();

            final chipWidth = textPainter.width + 48;

            if (usedWidth + chipWidth > maxWidth) break;

            usedWidth += chipWidth + 8;
            oneLine.add(t);
          }

          final List<TrendingKeyword> displayList =
              _showAllTrending ? _trending : oneLine;

          final bool hasMore = _trending.length > oneLine.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.trendWords,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // タイムスタンプ
                        Container(
                          height: 22,
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _trendingTimestamp,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // 🔥 更新ボタン
                        GestureDetector(
                          onTap:
                              _isRefreshingTrending ? null : _refreshTrending,
                          child: Container(
                            height: 22,
                            alignment: Alignment.bottomCenter,
                            child: _isRefreshingTrending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    size: 21,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 1.2,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6), // 下線色
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // チップ
              Wrap(
                spacing: 8,
                runSpacing: 1,
                children: displayList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final t = entry.value;

                  final keyword = t.keyword.trim();
                  if (keyword.isEmpty) return const SizedBox.shrink();

                  final bool isTop3 = index < 3;

                  return Material(
                    elevation: isTop3 ? 3 : 1.5,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.transparent,
                    child: ActionChip(
                      pressElevation: 0,
                      label: Text(
                        "#$keyword",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isTop3 ? FontWeight.w700 : FontWeight.w600,
                          color: isTop3 ? Colors.white : Colors.black87,
                        ),
                      ),
                      backgroundColor:
                          isTop3 ? const Color(0xFF7C3AED) : Colors.white,
                      side: isTop3
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFCFD5D5),
                              width: 1,
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      onPressed: () {
                        logger.i("🔥 Trending chip tapped: $keyword");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GenreVideosScreen(
                              categoryId: "",
                              categoryTitle: keyword,
                              keyword: keyword,
                              searchMode: "or",
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),

              // トグル
              if (hasMore) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showAllTrending = !_showAllTrending;
                        });

                        logger.i(
                            "🔁 Trending toggle: showAll=$_showAllTrending total=${_trending.length}");

                        // 🔥 レイアウト確定後にスクロール
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_scrollController.hasClients) return;

                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                          );
                        });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _showAllTrending
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 26,
                                color: toggleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showAllTrending ? t.showPartial : t.showAll,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: toggleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _isRefreshingTrending = false;

  Future<void> _refreshTrending() async {
    if (_isRefreshingTrending) return;

    setState(() {
      _isRefreshingTrending = true;
    });

    try {
      final api = context.read<YouTubeApiService>();

      final result = await api.fetchTrendingKeywords(
        regionCode: context.read<RegionProvider>().regionCode,
        max: 10,
        forceRefresh: true,
      );

      setState(() {
        _trending = result;
        _trendingLoaded = true;

        // 🔥 追加：表示リセット
        _showAllTrending = false;

        _trendingTimestamp = _buildTrendingNow();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingTrending = false;
        });
      }
    }
  }

  // ----------------------------------------------------
  // 🧩 本体
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final region = context.watch<RegionProvider>().regionCode;
    if (region != _lastRegion) {
      _lastRegion = region;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _networkError = false;
        });
      });
      cache.clear();
    }

    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final extraTopGap = isTablet ? 12.0 : 8.0;
    final double topBarOffset =
        safeTop + TopBarSpec.barContentHeight + extraTopGap;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: CustomScrollView(
          key: const PageStorageKey("genre_scroll"),
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topBarOffset)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.newPickupTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 1.2,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 16, 0),
                child: NewArrivalSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 16, 0),
                child: _buildTrendingChips(theme),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: UISpacing.bottomSpacer(
                  context,
                  hasFab: false,
                  hasAd: true,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class NewArrivalSection extends StatefulWidget {
  const NewArrivalSection({super.key});

  @override
  State<NewArrivalSection> createState() => _NewArrivalSectionState();
}

class _NewArrivalSectionState extends State<NewArrivalSection> {
  List<YouTubeVideo> videos = [];
  bool isLoading = true;
  final ScrollController _listController = ScrollController();

  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  static const double _sectionHeight = 230;

  @override
  void initState() {
    super.initState();
    fetch();

    _listController.addListener(() {
      if (!_listController.hasClients) return;

      final max = _listController.position.maxScrollExtent;
      final offset = _listController.offset;

      setState(() {
        _canScrollLeft = offset > 5;
        _canScrollRight = offset < max - 5;
      });
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();

    final kw = _genres[_selectedIndex]["keyword"]!;

    logger.i("[NewArrival fetch] q=$kw region=$region");

    // =========================
    // 🔥 キャッシュヒット
    // =========================
    final now = DateTime.now();
    final cachedAt = cacheTime[kw];

    if (!forceRefresh &&
        cache.containsKey(kw) &&
        cachedAt != null &&
        now.difference(cachedAt).inMinutes < 10) {
      logger.i("✅ cache hit: $kw");

      setState(() {
        videos = cache[kw]!;
        isLoading = false;
      });

      return;
    }

    // =========================
    // 🌐 API fetch
    // =========================
    try {
      final list = await api.searchWithStats(
        categoryId: "2000",
        keyword: kw,
        searchMode: "or",
        maxResults: 5,
        regionCode: region,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        videos = list;
        isLoading = false;

        // 🔥 キャッシュ保存
        cache[kw] = list;
        cacheTime[kw] = DateTime.now();
      });
    } catch (e) {
      logger.e("NewArrival fetch error: $e");

      if (!mounted) return;

      setState(() {
        videos = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(), // ← 常に表示
        const SizedBox(height: 4),
        _buildContent(), // ← 状態ごとに切替
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_genres.length, (index) {
            final isSelected = index == _selectedIndex;

            final bgColor = isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent;

            final textColor = isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface;

            return Padding(
              padding:
                  EdgeInsets.only(right: index == _genres.length - 1 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  if (_selectedIndex == index) return;

                  setState(() {
                    _selectedIndex = index;
                    isLoading = true;
                  });

                  fetch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _genres[index]["label"]!,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildList() {
    return SizedBox(
      height: _sectionHeight,
      child: Stack(
        children: [
          ListView.builder(
            controller: _listController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final isFirst = i == 0;
              final isLast = i == videos.length - 1;

              return Padding(
                padding: EdgeInsets.only(
                  left: isFirst ? 8 : 0,
                  right: isLast ? 8 : 0,
                ),
                child: VideoListTopic(
                  video: videos[i],
                  rank: i + 1,
                ),
              );
            },
          ),

          // 左矢印
          if (_canScrollLeft)
            Positioned(
              left: 4,
              top: 0,
              bottom: 15,
              child: IgnorePointer(
                child: Center(
                  child: _buildScrollHintIcon(
                    context,
                    icon: Icons.chevron_left,
                  ),
                ),
              ),
            ),

          // 右矢印
          if (_canScrollRight)
            Positioned(
              right: 4,
              top: 0,
              bottom: 15,
              child: IgnorePointer(
                child: Center(
                  child: _buildScrollHintIcon(
                    context,
                    icon: Icons.chevron_right,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollHintIcon(
    BuildContext context, {
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 26,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: _sectionHeight,
      child: _buildInner(),
    );
  }

  Widget _buildInner() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videos.isEmpty) {
      return _buildEmpty();
    }

    return _buildList();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            "まだ新着動画がありません",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
