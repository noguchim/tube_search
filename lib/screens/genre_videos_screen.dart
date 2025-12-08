import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/youtube_api_service.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/custom_glass_app_bar.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

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
    final d = _scrollController.position.userScrollDirection;

    if (d == ScrollDirection.reverse && !_isScrollingDown) {
      _isScrollingDown = true;
      widget.onScrollChanged?.call(true);
    } else if (d == ScrollDirection.forward && _isScrollingDown) {
      _isScrollingDown = false;
      widget.onScrollChanged?.call(false);
    }
  }

  String shortTitle(String t) =>
      t.length > 8 ? '${t.substring(0, 8)}…' : t;

  // ---------------------------------------------------------
  // ✨ ジャンル or キーワード動画取得
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    final kw = widget.keyword;

    if (kw != null && kw.trim().isNotEmpty) {
      final search = await _apiService.searchVideosByKeyword(
        kw,
        maxResults: 50,
      );

      if (search.isEmpty) return [];

      final ids = search.map((v) => v.id).join(',');
      final detail = await _apiService.fetchVideosByIds(ids);

      final videos = detail
          .map((v) => {
        'id': v.id,
        'title': v.title,
        'thumbnailUrl': v.thumbnailUrl,
        'channelTitle': v.channelTitle,
        'publishedAt': v.publishedAt?.toIso8601String(),
        'viewCount': v.viewCount ?? 0,
      })
          .toList();

      videos.sort((a, b) {
        final va = (a['viewCount'] ?? 0) as int;
        final vb = (b['viewCount'] ?? 0) as int;
        return vb.compareTo(va);
      });

      setState(() => _fetchedAt = DateTime.now());
      return videos;
    }

    // Popular API
    final list = await _apiService.fetchPopularVideos(
      videoCategoryId: widget.categoryId,
      maxResults: 50,
    );

    final videos = list
        .map((v) => {
      'id': v.id,
      'title': v.title,
      'thumbnailUrl': v.thumbnailUrl,
      'channelTitle': v.channelTitle,
      'publishedAt': v.publishedAt?.toIso8601String(),
      'viewCount': v.viewCount ?? 0,
    })
        .toList();

    videos.sort((a, b) {
      final va = (a['viewCount'] ?? 0) as int;
      final vb = (b['viewCount'] ?? 0) as int;
      return vb.compareTo(va);
    });

    setState(() => _fetchedAt = DateTime.now());
    return videos;
  }

  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await _fetchVideos();
      setState(() => _futureVideos = Future.value(data));
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatFetchedAt() {
    if (_fetchedAt == null) return "";
    return "${DateFormat("M/d HH:mm").format(_fetchedAt!)} 更新";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =====================================================
          // 🔥 本体 FutureBuilder
          // =====================================================
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureVideos,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("エラー: ${snap.error}"));
              }
              if (!snap.hasData || snap.data!.isEmpty) {
                return Center(
                  child: Text(
                    "動画が見つかりません",
                    style: TextStyle(color: onSurface.withValues(alpha: 0.8)),
                  ),
                );
              }

              final videos = snap.data!;

              return RefreshIndicator(
                onRefresh: _refreshVideos,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ---------------------------------------------------------
                    // Glass AppBar（戻るボタンはここに含めない）
                    // ---------------------------------------------------------
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      expandedHeight: 65,
                      automaticallyImplyLeading: false,
                      flexibleSpace: CustomGlassAppBar(
                        title: '人気：${shortTitle(widget.categoryTitle)}',
                        showRefreshButton: true,
                        isRefreshing: _isRefreshing,
                        onRefreshPressed: _refreshVideos,
                      ),
                    ),

                    // ---------------------------------------------------------
                    // 更新時間バー
                    // ---------------------------------------------------------
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

                    // ---------------------------------------------------------
                    // リスト
                    // ---------------------------------------------------------
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

          // =====================================================
          // 🔙 戻るボタン（CustomGlassAppBar外で独自配置）
          // =====================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 8,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: onSurface,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
