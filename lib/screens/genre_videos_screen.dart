import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/youtube_api_service.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

class GenreVideosScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  final String? keyword; // ← ここ重要（独自カテゴリ用）
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

  String shortTitle(String t) {
    return t.length > 8 ? '${t.substring(0, 8)}…' : t;
  }

  /// 🎥 指定ジャンル or キーワードの動画取得
  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    final String? kw = widget.keyword;

    // ----------------------------------------------------
    // ① 🔍 キーワード検索の場合 → Search API（categoryId 付けない）
    // ----------------------------------------------------
    if (kw != null && kw.trim().isNotEmpty) {
      final searchResults = await _apiService.searchVideosByKeyword(
        kw,
        maxResults: 50,
        debugRaw: true,
      );

      if (searchResults.isEmpty) return [];

      // ID 並列取得して viewCount 補完
      final ids = searchResults.map((v) => v.id).join(',');

      final detailedList = await _apiService.fetchVideosByIds(
        ids,
        debugRaw: true,
      );

      final videos = detailedList.map((v) {
        return {
          'id': v.id,
          'title': v.title,
          'thumbnailUrl': v.thumbnailUrl,
          'channelTitle': v.channelTitle,
          'publishedAt': v.publishedAt?.toIso8601String(),
          'viewCount': v.viewCount ?? 0,
        };
      }).toList();

      videos.sort((a, b) {
        return ((b['viewCount'] ?? 0) as int)
            .compareTo((a['viewCount'] ?? 0) as int);
      });

      setState(() => _fetchedAt = DateTime.now());
      return videos;
    }

    // ----------------------------------------------------
    // ② 🏆 カテゴリ人気動画（Popular API）
    // ----------------------------------------------------
    final popularList = await _apiService.fetchPopularVideos(
      videoCategoryId: widget.categoryId,
      maxResults: 50,
      debugRaw: true,
    );

    final videos = popularList.map((v) {
      return {
        'id': v.id,
        'title': v.title,
        'thumbnailUrl': v.thumbnailUrl,
        'channelTitle': v.channelTitle,
        'publishedAt': v.publishedAt?.toIso8601String(),
        'viewCount': v.viewCount ?? 0,
      };
    }).toList();

    videos.sort((a, b) {
      return ((b['viewCount'] ?? 0) as int)
          .compareTo((a['viewCount'] ?? 0) as int);
    });

    setState(() => _fetchedAt = DateTime.now());
    return videos;
  }

  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await _fetchVideos();
      setState(() {
        _futureVideos = Future.value(data);
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureVideos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("エラー: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("動画が見つかりません"));
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
                      expandedHeight: 85,
                      automaticallyImplyLeading: false,
                      flexibleSpace: CustomGlassAppBar(
                        title: '人気：${shortTitle(widget.categoryTitle)}',
                        showRefreshButton: true,
                        isRefreshing: _isRefreshing,
                        onRefreshPressed: _refreshVideos,
                      ),
                    ),

                    if (_fetchedAt != null)
                      SliverToBoxAdapter(
                        child: Container(
                          color: const Color(0xFFE4E8EC),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(
                                _formatFetchedAt(),
                                style: const TextStyle(
                                  color: Color(0xFF475569),
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
                            (context, i) => VideoListTile(
                          video: videos[i],
                          rank: i + 1,
                        ),
                        childCount: videos.length,
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SafeArea(top: false, child: SizedBox(height: 0))),
                  ],
                ),
              );
            },
          ),

          /// 左上の戻るボタン
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF1E293B)),
              iconSize: 26,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
