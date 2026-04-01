import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/data/youtube_video.dart';

import '../l10n/app_localizations.dart';
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
import '../widgets/density_fab.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/network_error_view.dart';
import '../widgets/popular_big_section.dart';
import '../widgets/popular_middle_section.dart';
import '../widgets/popular_small_section.dart';
import '../widgets/top_bar.dart';

class PopularVideosScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const PopularVideosScreen({
    super.key,
    this.onScrollChanged,
  });

  @override
  State<PopularVideosScreen> createState() => _PopularVideosScreenState();
}

class _PopularVideosScreenState extends State<PopularVideosScreen>
    with AutomaticKeepAliveClientMixin<PopularVideosScreen> {
  @override
  bool get wantKeepAlive => true;
  String _currentRegion = "JP";
  late Future<List<YouTubeVideo>> _futureVideos;
  bool _isScrollingDown = false;
  final ScrollController _scrollController = ScrollController();
  int _lastLimit = 20;

  late final IapProvider _iapProvider;
  late final RegionProvider _regionProvider;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _futureVideos = _fetchVideos();
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

  // void _onScroll() {
  //   if (!_scrollController.hasClients) return;
  //
  //   // ===== 既存：スクロール方向検知 =====
  //   final direction = _scrollController.position.userScrollDirection;
  //   if (direction == ScrollDirection.reverse && !_isScrollingDown) {
  //     _isScrollingDown = true;
  //     widget.onScrollChanged?.call(true);
  //   } else if (direction == ScrollDirection.forward && _isScrollingDown) {
  //     _isScrollingDown = false;
  //     widget.onScrollChanged?.call(false);
  //   }
  // }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    // 🔥 トップ付近は常に表示（最重要）
    if (offset <= 10) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        widget.onScrollChanged?.call(false);
      }
      _lastOffset = offset;
      return;
    }

    final delta = offset - _lastOffset;

    // 🔽 下スクロール（ある程度動いた時だけ）
    if (delta > 5) {
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        widget.onScrollChanged?.call(true);
      }
    }

    // 🔼 上スクロール
    else if (delta < -5) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        widget.onScrollChanged?.call(false);
      }
    }

    _lastOffset = offset;
  }

  Future<List<YouTubeVideo>> _fetchVideos({bool forceRefresh = false}) async {
    final iap = context.read<IapProvider>();
    final limit = LimitService.videoListLimit(iap);
    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();

    final videos = await api.fetchPopularVideos(
      maxResults: limit,
      regionCode: region,
      forceRefresh: forceRefresh,
    );

    return videos.take(limit).toList();
  }

  Future<void> _refreshVideos() async {
    try {
      final iap = context.read<IapProvider>();
      final limit = LimitService.videoListLimit(iap);

      final online = await _isOnline();

      final region = context.read<RegionProvider>().regionCode;
      final api = context.read<YouTubeApiService>();

      final videos = await api.fetchPopularVideos(
        maxResults: limit,
        regionCode: region,
        forceRefresh: !online,
      );

      final trimmed = videos.take(limit).toList();

      setState(() {
        _futureVideos = Future.value(trimmed);
      });
    } catch (e) {
      setState(() {
        _futureVideos = Future.error(e);
      });
    }
  }

  void _setFutureVideos(Future<List<YouTubeVideo>> future) {
    setState(() {
      _futureVideos = future;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    final density = context.watch<DensityProvider>().density;

    final expanded = context.watch<ExpandedVideoController>();
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final extraTopGap = isTablet ? 12.0 : 8.0;
    final double topBarOffset =
        safeTop + TopBarSpec.barContentHeight + extraTopGap;
    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: adsRemoved ? 15 : 45), // ← AdMob分持ち上げ
        child: DensityFab(
          density: density,
          onToggle: () => context.read<DensityProvider>().toggle(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FutureBuilder<List<YouTubeVideo>>(
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
                      child: SizedBox(height: topBarOffset),
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

              // =============================
              // 前面：Expanded Overlay
              // =============================
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
    );
  }
}
