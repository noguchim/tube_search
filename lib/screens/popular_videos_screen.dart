import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/video_list_tile_top_rank.dart';
import 'package:tube_search/widgets/video_overlay_card.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/card_density_prefs.dart';
import '../widgets/density_fab.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/network_error_view.dart';
import '../widgets/video_grid_tile.dart';
import '../widgets/video_list_tile_small.dart';

class PopularVideosScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const PopularVideosScreen({super.key, this.onScrollChanged});

  @override
  State<PopularVideosScreen> createState() => _PopularVideosScreenState();
}

class _PopularVideosScreenState extends State<PopularVideosScreen>
    with AutomaticKeepAliveClientMixin<PopularVideosScreen> {
  @override
  bool get wantKeepAlive => true;
  String _currentRegion = "JP";
  final YouTubeApiService _apiService = YouTubeApiService();
  late Future<List<Map<String, dynamic>>> _futureVideos;
  bool _isRefreshing = false;
  bool _isScrollingDown = false;
  final ScrollController _scrollController = ScrollController();
  int _lastLimit = 20;
  static const _densityKey = 'popular_card_density';
  CardDensity _density = CardDensity.big;
  late final IapProvider _iapProvider;
  late final RegionProvider _regionProvider;
  DateTime? _lastFetchedAt;
  Map<String, dynamic>? _expandedVideo;
  int? _expandedRank;

  @override
  void initState() {
    super.initState();
    _initDensity();
    _futureVideos = _fetchVideos();
    _lastFetchedAt = DateTime.now();
    _scrollController.addListener(_onScroll);
  }

  bool _didBind = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBind) return;
    _didBind = true;

    _iapProvider = context.read<IapProvider>();
    _regionProvider = context.read<RegionProvider>();

    _lastLimit = LimitService.videoListLimit(_iapProvider);
    _currentRegion = _regionProvider.regionCode;

    _iapProvider.addListener(_onIapChanged);
    _regionProvider.addListener(_onRegionChanged);
  }

  @override
  void dispose() {
    _iapProvider.removeListener(_onIapChanged);
    _regionProvider.removeListener(_onRegionChanged);
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // ===== 既存：スクロール方向検知 =====
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_isScrollingDown) {
      _isScrollingDown = true;
      widget.onScrollChanged?.call(true);
    } else if (direction == ScrollDirection.forward && _isScrollingDown) {
      _isScrollingDown = false;
      widget.onScrollChanged?.call(false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVideos(
      {bool forceRefresh = false}) async {
    final iap = context.read<IapProvider>();
    final limit = LimitService.videoListLimit(iap);
    final region = context.read<RegionProvider>().regionCode;
    final videos = await _apiService.fetchPopularVideos(
      maxResults: LimitService.videoListLimit(iap),
      regionCode: region,
      forceRefresh: forceRefresh, // ← 重要
    );

    _lastFetchedAt = DateTime.now();

    final mapped = videos.map((v) {
      return {
        'id': v.id,
        'title': v.title,
        'thumbnailUrl': v.thumbnailUrl,
        'channelTitle': v.channelTitle,
        'publishedAt': v.publishedAt?.toIso8601String(),
        'viewCount': v.viewCount ?? 0,
        'durationSeconds': v.durationSeconds ?? 0,
      };
    }).toList();

    mapped.sort(
        (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int));

    return mapped.take(limit).toList();
  }

  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);

    try {
      // 🔥 IAP 上限適用
      final iap = context.read<IapProvider>();
      final limit = LimitService.videoListLimit(iap);

      final online = await _isOnline();

      // 例外が出れば catch に飛ぶ
      final region = context.read<RegionProvider>().regionCode;
      final videos = await _apiService.fetchPopularVideos(
        maxResults: limit,
        regionCode: region,
        // 🟣 ネットが不安定なら必ず通信しに行く（→失敗したらエラー画面）
        forceRefresh: !online,
      );

      final mapped = videos.map((v) {
        return {
          'id': v.id,
          'title': v.title,
          'thumbnailUrl': v.thumbnailUrl,
          'channelTitle': v.channelTitle,
          'publishedAt': v.publishedAt?.toIso8601String(),
          'viewCount': v.viewCount ?? 0,
          'durationSeconds': v.durationSeconds ?? 0,
        };
      }).toList();

      mapped.sort(
          (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int));

      final trimmed = mapped.take(limit).toList();

      // 🔥 成功 → FutureBuilder にデータを渡す
      setState(() {
        _futureVideos = Future.value(trimmed);
        _lastFetchedAt = DateTime.now();
      });
    } catch (e) {
      // ❗ 例外時 → FutureBuilder にエラーを渡す
      setState(() {
        _futureVideos = Future.error(e);
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _setFutureVideos(Future<List<Map<String, dynamic>>> future) {
    setState(() {
      _futureVideos = future;
      _lastFetchedAt = DateTime.now(); // ✅ "表示用" 更新時刻
    });
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  void _onIapChanged() {
    if (!mounted) return;
    final currentLimit = LimitService.videoListLimit(_iapProvider);
    if (currentLimit == _lastLimit) return;

    _lastLimit = currentLimit;
    _setFutureVideos(_fetchVideos(forceRefresh: true));
  }

  void _onRegionChanged() {
    if (!mounted) return;
    final region = _regionProvider.regionCode;
    if (region == _currentRegion) return;

    _currentRegion = region;
    _setFutureVideos(_fetchVideos(forceRefresh: true));
  }

  Widget _buildBigSliver(List<Map<String, dynamic>> videos) {
    if (videos.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final topVideo = videos.first;
    final restVideos =
        videos.length > 1 ? videos.sublist(1) : <Map<String, dynamic>>[];

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          if (!isLandscape) ...[
            // =========================
            // 縦向き（従来通り）
            // =========================
            VideoListTileTopRank(
              video: topVideo,
              rank: 1,
            ),

            if (restVideos.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildResponsiveGrid(restVideos),
                ),
              ),
          ] else ...[
            // =========================
            // 横向き（2ペイン）
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左：BigCard
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20), // ← 揃えポイント
                      child: VideoListTileTopRank(
                        video: topVideo,
                        rank: 1,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 右：Grid
                  Expanded(
                    flex: 5,
                    child: _buildResponsiveGrid(restVideos),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Map<String, dynamic>> videos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxCardWidth = 240;
        const double spacing = 12;

        int crossAxisCount =
            (constraints.maxWidth / (maxCardWidth + spacing)).floor();

        crossAxisCount = crossAxisCount.clamp(2, 6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (context, index) {
            final video = videos[index];
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
        );
      },
    );
  }

  Widget _buildOverlayGrid(List<Map<String, dynamic>> videos) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isLandscape) {
      // 縦向き：従来の List
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];
            return VideoOverlayCard(
              video: video,
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
      );
    }

    // 横向き：Grid
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        12,
        16,
        12,
        0,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];
            return VideoOverlayCard(
              video: video,
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 横向き2列
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 9,
        ),
      ),
    );
  }

  Widget _buildResponsiveOverlayGrid(
    List<Map<String, dynamic>> videos,
  ) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    // ✅ ここが最重要
    final double shortest = media.size.shortestSide;
    final bool isPhone = shortest < 600;

    const double mainSpacing = 0;
    const double crossSpacing = 0;

    final double maxTileWidth = shortest >= 900 ? 360 : 320;

    SliverGridDelegate gridDelegate;

    if (isPhone && !isLandscape) {
      // 📱 Phone 縦：1列
      gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
    } else if (isPhone && isLandscape) {
      // 📱 Phone 横：2列固定（Pixel7aはここ）
      gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
    } else {
      // 📲 Tablet / 大画面
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxTileWidth,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        8,
        isLandscape ? 8 : 0,
        8,
        0,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];
            return VideoOverlayCard(
              video: video,
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: gridDelegate,
      ),
    );
  }

  Widget _buildResponsiveSmallList(List<Map<String, dynamic>> videos) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final shortest = mq.size.shortestSide;

    final isPhone = shortest < 600;

    // ✅ Phone 横向き → 2列
    if (isPhone && isLandscape) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final video = videos[index];
              return VideoListTileSmall(
                video: video,
                rank: index + 1,
              );
            },
            childCount: videos.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 128, // ✅ 高さ固定
          ),
        ),
      );
    }

    // ✅ 縦 or Tablet → 1列
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final video = videos[index];
          return VideoListTileSmall(
            video: video,
            rank: index + 1,
          );
        },
        childCount: videos.length,
      ),
    );
  }

  Widget _buildSmallGrid(List<Map<String, dynamic>> videos) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    final bool isTablet = shortestSide >= 600;

    // =========================
    // 列数
    // =========================
    final int crossAxisCount = isTablet
        ? 3
        : isLandscape
            ? 2
            : 1;

    // =========================
    // 高さ（Smallは密度優先）
    // =========================
    final double tileHeight = isTablet
        ? 112 // ← Tabletでも詰める（重要）
        : isLandscape
            ? 104 // Phone 横
            : 128; // Phone 縦

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        6,
        20,
        6,
        8,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return VideoListTileSmall(
              video: videos[index],
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: tileHeight,
          mainAxisSpacing: isLandscape ? 4 : 6,
          crossAxisSpacing: isLandscape ? 4 : 6,
        ),
      ),
    );
  }

  Widget _buildSmallList(List<Map<String, dynamic>> videos) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return VideoListTileSmall(
            video: videos[index],
            rank: index + 1,
          );
        },
        childCount: videos.length,
      ),
    );
  }

  Widget _densityControl(List<Map<String, dynamic>> videos) {
    switch (_density) {
      case CardDensity.big:
        return _buildBigSliver(videos);

      case CardDensity.middle:
        return _buildResponsiveOverlayGrid(videos);

      case CardDensity.small:
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        if (isLandscape) {
          return _buildSmallGrid(videos); // 横 → 2列
        } else {
          return _buildSmallList(videos); // 縦 → 1列
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45), // ← AdMob分持ち上げ
        child: DensityFab(
          density: _density,
          onToggle: _toggleDensity,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureVideos,
        builder: (context, snapshot) {
          // 🔄 ローディング
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ エラー時（機内モード含む）
          if (snapshot.hasError) {
            return NetworkErrorView(
              onRetry: () {
                _setFutureVideos(_fetchVideos(forceRefresh: true));
              },
            );
          }

          // ⚠ データなし
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noVideosFound,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
              ),
            );
          }

          final videos = snapshot.data!;

          return Stack(
            children: [
              // =============================
              // 背面：既存のリスト（今のコードそのまま）
              // =============================
              RefreshIndicator(
                onRefresh: _refreshVideos,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50 + MediaQuery.of(context).padding.top,
                      ),
                    ),
                    _densityControl(videos),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 70),
                    ),
                  ],
                ),
              ),

              // =============================
              // 前面：Expanded Overlay
              // =============================
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
    );
  }
}
