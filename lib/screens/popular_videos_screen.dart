import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../widgets/custom_glass_app_bar.dart';
import '../widgets/network_error_view.dart';
import '../widgets/repeat_settings_panel.dart';
import '../widgets/video_list_tile.dart';

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
  int _lastLimit = 10;

  @override
  void initState() {
    super.initState();
    _futureVideos = _fetchVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
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
    final region = context.read<RegionProvider>().regionCode;
    final videos = await _apiService.fetchPopularVideos(
      maxResults: LimitService.videoListLimit(iap),
      regionCode: region,
      forceRefresh: forceRefresh, // ← 重要
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

    return mapped;
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

      // 🔥 成功 → FutureBuilder にデータを渡す
      setState(() {
        _futureVideos = Future.value(mapped);
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

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    // 上限（IAP反映）を監視
    final iap = context.watch<IapProvider>();
    final currentLimit = LimitService.videoListLimit(iap);

    // 🟣 上限が変わったら自動で再取得（＝キャッシュ無視で最新取得）
    if (currentLimit != _lastLimit) {
      _lastLimit = currentLimit;

      setState(() {
        _futureVideos = _fetchVideos(forceRefresh: true);
      });
    }

    // 🌎 地域変更 → 再取得（＝キャッシュ無視で最新取得）
    final region = context.watch<RegionProvider>().regionCode;
    if (region != _currentRegion) {
      _currentRegion = region;
      setState(() {
        _futureVideos = _fetchVideos(forceRefresh: true);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                setState(() {
                  _futureVideos = _fetchVideos(forceRefresh: true);
                });
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

          return RefreshIndicator(
            onRefresh: _refreshVideos,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 70,
                  flexibleSpace: CustomGlassAppBar(
                    title: AppLocalizations.of(context)!.popularTitle,
                    showRefreshButton: true,
                    isRefreshing: _isRefreshing,
                    showInfoButton: true,
                    onRefreshPressed: _refreshVideos,
                  ),
                ),

                // Phase2対応(連続再生)
                // SliverToBoxAdapter(
                //   child: Container(
                //     margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                //     padding: const EdgeInsets.all(20),
                //     decoration: BoxDecoration(
                //       color: Theme.of(context).colorScheme.surface,
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(
                //         color: Theme.of(context)
                //             .colorScheme
                //             .onSurface
                //             .withValues(alpha: 0.08),
                //       ),
                //     ),
                //     child: Center(
                //       child: ElevatedButton(
                //         onPressed: () async {
                //           // Navigator.pop(context); // もしダイアログ上なら閉じる
                //
                //           await showRepeatSettingsPanel(
                //             context: context,
                //             videos: videos,
                //           );
                //         },
                //         child: const Text("連続再生を始める"),
                //       ),
                //     ),
                //   ),
                // ),

                SliverToBoxAdapter(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Navigator.pop(context); // もしダイアログ上なら閉じる

                        await showRepeatSettingsPanel(
                          context: context,
                          videos: videos,
                        );
                      },
                      child: const Text("連続再生を始める"),
                    ),
                  ),
                ),

                // --- 動画リスト ---
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => VideoListTile(
                      video: videos[index],
                      rank: index + 1,
                    ),
                    childCount: videos.length,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
