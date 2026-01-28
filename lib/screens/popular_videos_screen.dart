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
