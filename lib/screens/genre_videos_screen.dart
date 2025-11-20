import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/youtube_api_service.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/custom_app_bar.dart';
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
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_isScrollingDown) {
      _isScrollingDown = true;
      widget.onScrollChanged?.call(true);
    } else if (direction == ScrollDirection.forward && _isScrollingDown) {
      _isScrollingDown = false;
      widget.onScrollChanged?.call(false);
    }
  }

  /// 🎥 指定ジャンルの人気動画取得＋再生数でソート
  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    // Search API をキーワード無しで使う → " "（スペース）
    final videoList = await _apiService.searchVideosByCategoryAndKeyword(
      widget.categoryId,
      " ",
    );

    // モデル → Map に変換
    final videos = videoList.map((v) {
      return {
        'id': v.id,
        'title': v.title,
        'thumbnailUrl': v.thumbnailUrl,
        'channelTitle': v.channelTitle,
        'publishedAt': v.publishedAt?.toIso8601String(),
        'viewCount': v.viewCount ?? 0,
      };
    }).toList();

    // ✔ viewCount でソート（int にキャスト）
    videos.sort((a, b) {
      final viewA = (a['viewCount'] as int?) ?? 0;
      final viewB = (b['viewCount'] as int?) ?? 0;
      return viewB.compareTo(viewA);
    });

    setState(() => _fetchedAt = DateTime.now());
    return videos;
  }

  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);
    try {
      final videos = await _fetchVideos();
      setState(() {
        _futureVideos = Future.value(videos);
        _fetchedAt = DateTime.now();
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatFetchedAt() {
    if (_fetchedAt == null) return '';
    final formatter = DateFormat('M/d HH:mm');
    return '${formatter.format(_fetchedAt!)} 更新';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: Stack(
        children: [
          /// 📜 メインスクロール領域
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureVideos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('エラー: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('動画が見つかりません'));
              }

              final videos = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refreshVideos,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    /// 🪩 ガラスAppBar（戻るボタンなし）
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      expandedHeight: 82,
                      automaticallyImplyLeading: false,
                      flexibleSpace: CustomGlassAppBar(
                        title: '人気：${widget.categoryTitle}',
                        showRefreshButton: true,
                        isRefreshing: _isRefreshing,
                        onRefreshPressed: _refreshVideos,
                      ),
                    ),

                    /// 🕓 更新時刻
                    if (_fetchedAt != null)
                      SliverToBoxAdapter(
                        child: Container(
                          color: const Color(0xFFE4E8EC),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 14),
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

                    /// 🎥 動画リスト
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
                      child: SafeArea(top: false, child: SizedBox(height: 0)),
                    ),
                  ],
                ),
              );
            },
          ),

          /// 🔙 画面左上に固定配置の戻るボタン（AppBar外）
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 10,
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, _) {
                // スクロール位置に応じて背景の透明度を変化（上部では目立たせない）
                final opacity = (_scrollController.hasClients && _scrollController.offset > 20)
                    ? 0.75
                    : 0.25; // ← 最上部でほぼ透明

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: opacity),
                        const Color(0xFFE5E8EC).withValues(alpha: opacity - 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                    boxShadow: [
                      if (opacity > 0.3)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 5,
                          offset: const Offset(1, 2),
                        ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B), // ✅ AppBar更新ボタンと同色
                    ),
                    iconSize: 26,
                    onPressed: () => Navigator.pop(context),
                    tooltip: '戻る',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
