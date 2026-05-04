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
  State<PopularVideosScreen> createState() => PopularVideosScreenState();
}

class PopularVideosScreenState extends State<PopularVideosScreen>
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
  List<YouTubeVideo>? _videos;
  bool _isLoading = true;
  Object? _error;

  void scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    final api = context.read<YouTubeApiService>();
    final region = context.read<RegionProvider>().regionCode;
    final limit = LimitService.videoListLimit(context.read<IapProvider>());

    final cached = api.getCachedPopular(
      regionCode: region,
      max: limit,
    );

    if (cached.isNotEmpty) {
      _videos = cached;
      _isLoading = false;
    } else {
      _loadVideos();
    }

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

  Future<void> _loadVideos({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final videos = await _fetchVideos(forceRefresh: forceRefresh);

      if (!mounted) return;

      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<List<YouTubeVideo>> _fetchVideos({bool forceRefresh = false}) async {
    final iap = context.read<IapProvider>();
    final limit = LimitService.videoListLimit(iap);
    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();

    final videos = await api.fetchPopularVideos(
      maxResults: limit,
      hours: 12,
      regionCode: region,
      forceRefresh: forceRefresh,
    );

    // 📅 履歴
    // await api.fetchPopularVideos(
    //   regionCode: region,
    //   date: "2026-04-25",
    //   maxResults: 20,
    // );

    return videos.take(limit).toList();
  }

  void _setFutureVideos(Future<List<YouTubeVideo>> future) {
    setState(() {
      _futureVideos = future;
    });
  }

  void _onIapChanged() {
    final limit = LimitService.videoListLimit(_iapProvider);

    final api = context.read<YouTubeApiService>();
    final region = _regionProvider.regionCode;

    final cached = api.getCachedPopular(
      regionCode: region,
      max: limit,
    );

    if (cached.isNotEmpty) {
      _setFutureVideos(Future.value(cached));
    } else {
      _setFutureVideos(_fetchVideos(forceRefresh: true));
    }
  }

  void _onRegionChanged() {
    final region = _regionProvider.regionCode;

    final api = context.read<YouTubeApiService>();

    final cached = api.getCachedPopular(
      regionCode: region,
      max: _lastLimit,
    );

    if (cached.isNotEmpty) {
      _setFutureVideos(Future.value(cached));
    } else {
      _setFutureVideos(_fetchVideos(forceRefresh: true));
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

    final double topBarOffset = TopBarSpec.total(safeTop) + extraTopGap;

    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);

    // =========================================================
    // 🔥 状態分岐（ここが本体）
    // =========================================================

    Widget body;

    // 🔄 ローディング
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    }

    // ❌ エラー
    else if (_error != null) {
      body = NetworkErrorView(
        onRetry: () {
          _loadVideos(forceRefresh: true);
        },
      );
    }

    // ⚠ データなし
    else if (_videos == null || _videos!.isEmpty) {
      body = Center(
        child: Text(
          AppLocalizations.of(context)!.noVideosFound,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    // ✅ 正常表示
    else {
      final videos = _videos!;

      body = Stack(
        children: [
          // =============================
          // 背面：リスト
          // =============================
          RefreshIndicator(
            onRefresh: () => _loadVideos(forceRefresh: true),
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
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: adsRemoved ? 15 : 45),
        child: DensityFab(
          density: density,
          onToggle: () => context.read<DensityProvider>().toggle(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          body,
        ],
      ),
    );
  }
}
