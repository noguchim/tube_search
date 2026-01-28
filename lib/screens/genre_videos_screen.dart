import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/banner_ad_provider.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
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
import '../widgets/top_bar.dart';
import '../widgets/video_grid_tile.dart';

import '../widgets/video_list_tile_small.dart';
import '../widgets/video_list_tile_top_rank.dart';
import '../widgets/video_overlay_card.dart';

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

  bool _isRefreshing = false;
  bool _isScrollingDown = false;
  DateTime? _fetchedAt;
  int _lastLimit = 20;
  static const _densityKey = 'popular_card_density';
  CardDensity _density = CardDensity.big;

  bool _isSearching = false;
  Completer<List<Map<String, dynamic>>>? _activeRequest;
  Map<String, dynamic>? _expandedVideo;
  int? _expandedRank;
  bool _showTopBar = true;

  @override
  void initState() {
    super.initState();
    _futureVideos = _loadVideos();
    _scrollController.addListener(_onScroll);
    _initDensity();
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

  Future<void> _initDensity() async {
    final d = await CardDensityPrefs.load(key: _densityKey);
    if (!mounted) return;
    setState(() => _density = d);
  }

  void _toggleDensity() {
    final next = CardDensityPrefs.next(_density);
    setState(() => _density = next);
    CardDensityPrefs.save(next, key: _densityKey);
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
            _fetchedAt = DateTime.now();
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

        _fetchedAt = DateTime.now();
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

    setState(() => _isRefreshing = true);

    try {
      final data = await _loadVideos(forceRefresh: true); // ✅ refreshは強制fresh推奨
      if (!mounted) return;

      setState(() {
        _futureVideos = Future.value(data);
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      rethrow;
    }
  }

  Widget _buildBigSliver(List<Map<String, dynamic>> videos) {
    if (videos.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final topVideo = videos.first;
    final restVideos = videos.length > 1 ? videos.sublist(1) : [];

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          VideoListTileTopRank(
            video: topVideo,
            rank: 1,
          ),
          if (restVideos.isNotEmpty)
            Transform.translate(
              // NOTE:
              // 視覚的なカード連続感を出すために
              // Grid を BigCard に少し重ねている(-20)。
              // レイアウト上の余白ではなく視覚補正。
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: restVideos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 12,
                    childAspectRatio: 16 / 9,
                  ),
                  itemBuilder: (context, index) {
                    final video = restVideos[index];
                    final rank = index + 2;

                    return VideoGridTile(
                      video: video,
                      rank: rank,
                      onTap: () {
                        setState(() {
                          _expandedVideo = video;
                          _expandedRank = rank;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalSliver(List<Map<String, dynamic>> videos) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final video = videos[index];
          final rank = index + 1;

          switch (_density) {
            case CardDensity.middle:
              return VideoOverlayCard(
                video: video,
                rank: rank,
              );

            case CardDensity.small:
              return VideoListTileSmall(
                video: video,
                rank: rank,
              );

            case CardDensity.big:
            // BIG はここに来ない設計
              return const SizedBox.shrink();
          }
        },
        childCount: videos.length,
      ),
    );
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

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();
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
          density: _density,
          onToggle: _toggleDensity,
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
                        if (_density == CardDensity.big)
                          _buildBigSliver(videos)
                        else
                          _buildNormalSliver(videos),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 70),
                        ),
                      ],
                    ),
                  ),

                  // Expanded Overlay
                  if (_expandedVideo != null)
                    Positioned.fill(
                      child: ExpandedVideoOverlay(
                        video: _expandedVideo!,
                        rank: _expandedRank!,
                        onClose: () {
                          setState(() {
                            _expandedVideo = null;
                            _expandedRank = null;
                          });
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
              child: TopBar(
                mode: TopBarMode.back,
                title: topTitle,
                onBack: () {
                  Navigator.of(context).pop();
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
