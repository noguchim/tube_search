import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/youtube_api_service.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

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

  final YouTubeApiService _apiService = YouTubeApiService();
  late Future<List<Map<String, dynamic>>> _futureVideos;
  DateTime? _fetchedAt;
  bool _isRefreshing = false;
  bool _isScrollingDown = false;
  final ScrollController _scrollController = ScrollController();

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

  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    final videos = await _apiService.fetchPopularVideos();

    // モデル → Map（すべて String に統一）
    final mapped = videos.map((v) {
      return {
        'id': v.id,
        'title': v.title,
        'thumbnailUrl': v.thumbnailUrl,
        'channelTitle': v.channelTitle,
        'publishedAt': v.publishedAt?.toIso8601String(),
        'viewCount': (v.viewCount ?? 0).toString(), // ← String に統一（超重要）
      };
    }).toList();

    // 再生数で降順ソート（ランキングの index と合わせる）
    mapped.sort((a, b) {
      final viewA = int.tryParse(a['viewCount'] ?? '0') ?? 0;
      final viewB = int.tryParse(b['viewCount'] ?? '0') ?? 0;
      return viewB.compareTo(viewA); // 降順
    });

    setState(() => _fetchedAt = DateTime.now());
    return mapped;
  }


  Future<void> _refreshVideos() async {
    setState(() => _isRefreshing = true);

    try {
      final videos = await _apiService.fetchPopularVideos();

      // List<YouTubeVideo> → Map（すべて String に統一）
      final mapped = videos.map((v) {
        return {
          'id': v.id,
          'title': v.title,
          'thumbnailUrl': v.thumbnailUrl,
          'channelTitle': v.channelTitle,
          'publishedAt': v.publishedAt?.toIso8601String(),
          'viewCount': (v.viewCount ?? 0).toString(), // ← 超重要
        };
      }).toList();

      // 再生数で降順ソート（人気順に正しく並べる）
      mapped.sort((a, b) {
        final viewA = int.tryParse(a['viewCount'] ?? '0') ?? 0;
        final viewB = int.tryParse(b['viewCount'] ?? '0') ?? 0;
        return viewB.compareTo(viewA);
      });

      setState(() {
        _futureVideos = Future.value(mapped);
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
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                /// 🪩 メタリックAppBar（共通コンポーネント使用）
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 82,
                  flexibleSpace: CustomGlassAppBar(
                    title: '人気急上昇',
                    showRefreshButton: true,
                    isRefreshing: _isRefreshing,
                    onRefreshPressed: _refreshVideos,
                    showInfoButton: true, // ✅ 追加
                    infoMessage:
                    'YouTube急上昇ランキング（日本国内・トレンド反映） ${_formatFetchedAt()}',
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
    );
  }
}
