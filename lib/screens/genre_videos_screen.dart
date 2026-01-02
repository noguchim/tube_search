import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../widgets/custom_glass_app_bar.dart';
import '../widgets/network_error_view.dart';
import '../widgets/video_list_tile.dart';

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
  int _lastLimit = 10;

  @override
  void initState() {
    super.initState();
    _futureVideos = _loadVideos();
    _scrollController.addListener(_onScroll);
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

    if (d == ScrollDirection.reverse && !_isScrollingDown) {
      _isScrollingDown = true;
      widget.onScrollChanged?.call(true);
    } else if (d == ScrollDirection.forward && _isScrollingDown) {
      _isScrollingDown = false;
      widget.onScrollChanged?.call(false);
    }
  }

  String shortTitle(String t) => t.length > 8 ? '${t.substring(0, 8)}…' : t;

  // ---------------------------------------------------------
  // 🔥 API 統合フェッチ（キーワード or 人気ジャンル）
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadVideos(
      {bool forceRefresh = false}) async {
    final kw = widget.keyword?.trim();
    final cat = widget.categoryId == "0" ? "" : widget.categoryId;
    final iap = context.read<IapProvider>();
    final limit = LimitService.videoListLimit(iap);

    List<Map<String, dynamic>> videos = [];

    try {
      if (kw != null && kw.isNotEmpty) {
        // キーワード検索 → IDs → 詳細
        final region = context.read<RegionProvider>().regionCode;
        final search = await _apiService.searchWithStats(
          categoryId: cat,
          keyword: kw,
          maxResults: limit,
          regionCode: region,
          forceRefresh: forceRefresh,
        );

        if (search.isEmpty) {
          _fetchedAt = DateTime.now();
          return [];
        }

        final ids = search.map((v) => v.id).join(',');
        final detail = await _apiService.fetchVideosByIds(ids);

        videos = detail
            .map((v) => {
                  'id': v.id,
                  'title': v.title,
                  'thumbnailUrl': v.thumbnailUrl,
                  'channelTitle': v.channelTitle,
                  'publishedAt': v.publishedAt?.toIso8601String(),
                  'viewCount': v.viewCount ?? 0,
                })
            .toList();
      } else {
        // 人気ジャンル一覧
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
                })
            .toList();
      }

      // ソート & 更新時間
      videos.sort(
          (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int));
      _fetchedAt = DateTime.now();
      return videos;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Pull-to-refresh（setState は同期のみ）
  // ---------------------------------------------------------
  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);

    try {
      final data = await _loadVideos();
      setState(() {
        _futureVideos = Future.value(data);
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() => _isRefreshing = false);
      rethrow;
    }
  }

  String _formatFetchedAt() {
    if (_fetchedAt == null) return "";
    return "${DateFormat("M/d HH:mm").format(_fetchedAt!)} "
        "${AppLocalizations.of(context)!.update}";
  }

  // ---------------------------------------------------------
  // 🔥 UI 本体
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final iap = context.watch<IapProvider>();
    final currentLimit = LimitService.videoListLimit(iap);

    // 🟣 上限が変わったら自動で再取得（IAP購入直後に即反映）
    if (currentLimit != _lastLimit) {
      _lastLimit = currentLimit;

      setState(() {
        _futureVideos = _loadVideos();
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
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

              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noVideosFound,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }

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
                      automaticallyImplyLeading: false,
                      flexibleSpace: CustomGlassAppBar(
                        title: AppLocalizations.of(context)!.genrePopularTitle(
                          shortTitle(widget.categoryTitle),
                        ),
                        showRefreshButton: true,
                        isRefreshing: _isRefreshing,
                        onRefreshPressed: _refreshVideos,
                      ),
                    ),
                    if (_fetchedAt != null)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFE4E8EC),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.access_time,
                                  size: 14,
                                  color: onSurface.withValues(alpha: 0.7)),
                              const SizedBox(width: 4),
                              Text(
                                _formatFetchedAt(),
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            VideoListTile(video: videos[i], rank: i + 1),
                        childCount: videos.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SafeArea(top: false, child: SizedBox(height: 0)),
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔙 戻るボタン（GlassAppBar外）
          Positioned(
            top: MediaQuery.of(context).padding.top + 25,
            left: 8,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8), // ← 10 → 8 に縮小
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18, // ← 22 → 18 に縮小
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
