import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../providers/iap_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/ui_spacing.dart';
import '../widgets/ad_banner.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/network_error_view.dart';
import '../widgets/section_plain_videos.dart';
import '../widgets/top_bar_back.dart';

class VideoDetailScreen extends StatefulWidget {
  final YouTubeVideo video;
  final String title;

  const VideoDetailScreen({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  State<VideoDetailScreen> createState() => VideoDetailScreenState();
}

class VideoDetailScreenState extends State<VideoDetailScreen> {
  late Future<List<YouTubeVideo>> _futureVideos;
  late final ExpandedVideoController _expandedVideoController;

  @override
  void initState() {
    super.initState();
    _expandedVideoController = context.read<ExpandedVideoController>();
    _futureVideos = _loadVideos();
  }

  @override
  void dispose() {
    _expandedVideoController.close();
    super.dispose();
  }

  Future<List<YouTubeVideo>> _loadVideos() async {
    final api = context.read<YouTubeApiService>();

    // 関連動画取得
    final related = await api.fetchRelatedVideos(
      widget.video.id,
      max: 4,
    );

    // 🔥 先頭に現在動画
    final result = <YouTubeVideo>[
      widget.video,
    ];

    // 🔥 重複除去
    final seen = <String>{widget.video.id};

    for (final v in related) {
      if (v.id.isEmpty) continue;

      if (seen.contains(v.id)) continue;

      seen.add(v.id);
      result.add(v);
    }

    return result;
  }

  // ---------------------------------------------------------
  // 🔥 UI 本体
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = context.watch<ExpandedVideoController>();

    // ★ Favorite 状態変化を購読して同期
    context.watch<FavoritesService>();

    final adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);
    final bool shouldShowBanner = !adsRemoved;
    final controller = context.read<ExpandedVideoController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          FutureBuilder<List<YouTubeVideo>>(
            future: _futureVideos,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                logger.e("❌ FutureBuilder error: ${snap.error}");
                logger.e("❌ StackTrace: ${snap.stackTrace}");

                return NetworkErrorView(
                  onRetry: () {
                    setState(() {
                      _futureVideos = _loadVideos();
                    });
                  },
                );
              }

              final videos = snap.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 55 + MediaQuery.of(context).padding.top,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionPlainVideos(
                      videos: videos,
                      showRelatedTitle: true,
                    ),
                  ),
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
              );
            },
          ),

          // Expanded Overlay
          if (expanded.video != null)
            Positioned.fill(
              child: ExpandedVideoOverlay(
                video: expanded.video!,
                rank: expanded.rank!,
                onClose: () {
                  controller.close();
                },
              ),
            ),

          if (shouldShowBanner)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AdBanner(isMain: false),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBarBack(
              title: widget.title,
              onBack: Navigator.of(context).pop,
            ),
          ),
        ],
      ),
    );
  }
}
