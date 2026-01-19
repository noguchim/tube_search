import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/limit_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/card_density_prefs.dart';
import '../widgets/light_flat_app_bar.dart';
import '../widgets/network_error_view.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/video_list_tile_middle.dart';
import '../widgets/video_list_tile_small.dart';

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
  int _lastLimit = 20;
  static const _densityKey = 'popular_card_density';
  CardDensity _density = CardDensity.big;

  bool _isSearching = false;
  Completer<List<Map<String, dynamic>>>? _activeRequest;

  @override
  void initState() {
    super.initState();
    _futureVideos = _loadVideos();
    _scrollController.addListener(_onScroll);
    _initDensity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final iap = context.watch<IapProvider>();
    final currentLimit = LimitService.videoListLimit(iap);

    if (currentLimit != _lastLimit) {
      _lastLimit = currentLimit;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _futureVideos = _loadVideos(forceRefresh: true));
      });
    }
  }

  @override
  void dispose() {
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

  String shortTitle(String t) => t.length > 12 ? '${t.substring(0, 12)}…' : t;

  // ---------------------------------------------------------
  // 🔥 API 統合フェッチ（キーワード or 人気ジャンル）
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadVideos({bool forceRefresh = false}) {
    // ✅ すでに検索中 → 同じFutureを返して二重実行を防ぐ
    if (_isSearching && _activeRequest != null) {
      return _activeRequest!.future;
    }

    _isSearching = true;
    _activeRequest = Completer<List<Map<String, dynamic>>>();

    () async {
      final kw = widget.keyword?.trim();
      final cat = widget.categoryId == "0" ? "" : widget.categoryId;

      final iap = context.read<IapProvider>();
      final limit = LimitService.videoListLimit(iap);

      List<Map<String, dynamic>> videos = [];

      logger.w("🧮 limit=$limit (IAP purchased=${iap.isPurchased})");




      try {
        logger.i("🎯 loadVideos: kw=${kw ?? '(null)'} / cat=$cat");

        if (kw != null && kw.isNotEmpty) {
          // キーワード検索

          logger.i("🔎 mode=keywordSearch");

          final region = context.read<RegionProvider>().regionCode;

          var search = await _apiService.searchWithStats(
            categoryId: cat,
            keyword: kw,
            maxResults: limit,
            regionCode: region,
            forceRefresh: forceRefresh,
          );

          logger.w("📌 [kw]searchCount=${search.length}");

          // 0件ならカテゴリ無しでフォールバック
          if (search.isEmpty && cat.isNotEmpty) {
            search = await _apiService.searchWithStats(
              categoryId: "",
              keyword: kw,
              maxResults: limit,
              regionCode: region,
              forceRefresh: forceRefresh,
            );
          }

          if (search.isEmpty) {
            _fetchedAt = DateTime.now();
            _activeRequest?.complete([]);
            return;
          }

          final ids = search.map((v) => v.id).join(',');
          logger.w("📌 [kw]idsCount=${ids.split(',').length}");
          final detail = await _apiService.fetchVideosByIds(ids);

          videos = detail
              .map((v) => {
            'id': v.id,
            'title': v.title,
            'thumbnailUrl': v.thumbnailUrl,
            'channelTitle': v.channelTitle,
            'publishedAt': v.publishedAt?.toIso8601String(),
            'viewCount': v.viewCount ?? 0,
            'durationSeconds': v.durationSeconds ?? 0,
          })
              .toList();

          logger.w("📌 [kw]detailCount=${detail.length}");
        } else {
          // 人気ジャンル一覧

          logger.i("🔥 mode=popularGenreList");

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
            'durationSeconds': v.durationSeconds ?? 0,
          })
              .toList();

          logger.w("📌 [gr]listCount=${list.length}");
        }

        // ソート & 更新時間
        videos.sort(
              (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int),
        );

        videos = videos.take(limit).toList();

        _fetchedAt = DateTime.now();
        _activeRequest?.complete(videos);

      } catch (e, st) {
        // ✅ FutureBuilderに伝播できるようエラーもcompleteError
        if (!(_activeRequest?.isCompleted ?? true)) {
          _activeRequest?.completeError(e, st);
        }
      } finally {
        _isSearching = false;
        _activeRequest = null;
      }
    }();

    return _activeRequest!.future;
  }

  // ---------------------------------------------------------
  // 🔥 Pull-to-refresh（setState は同期のみ）
  // ---------------------------------------------------------
  Future<void> _refreshVideos() async {
    if (_isSearching) return; // ✅ 追加

    setState(() => _isRefreshing = true);

    try {
      final data = await _loadVideos(forceRefresh: true); // ✅ refreshは強制fresh推奨
      if (!mounted) return;

      setState(() {
        _futureVideos = Future.value(data);
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
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
                      flexibleSpace: LightFlatAppBar(
                        title: shortTitle(widget.categoryTitle),
                        showRefreshButton: true,
                        isRefreshing: _isRefreshing,
                        onRefreshPressed: _refreshVideos,
                        showDensityButton: true,
                        density: _density,
                        onToggleDensity: _toggleDensity,
                        titleAlign: AppBarTitleAlign.left,
                        reserveLeadingSpace: true,
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
                        (context, i) {
                          final video = videos[i];

                          switch (_density) {
                            case CardDensity.big:
                              return VideoListTile(video: video, rank: i + 1);

                            case CardDensity.middle:
                              return VideoListTileMiddle(
                                  video: video, rank: i + 1);

                            case CardDensity.small:
                              return VideoListTileSmall(
                                  video: video, rank: i + 1);
                          }
                        },
                        childCount: videos.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SafeArea(top: false, child: SizedBox(height: 50)),
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔙 戻るボタン（GlassAppBar外）
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
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
