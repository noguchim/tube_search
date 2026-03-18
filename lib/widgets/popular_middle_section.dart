import 'package:flutter/material.dart';

import '../data/youtube_video.dart';
import '../widgets/video_overlay_card.dart';

class PopularMiddleSection extends StatelessWidget {
  final List<YouTubeVideo> videos;

  const PopularMiddleSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool isTablet = media.size.shortestSide >= 600;

    // =========================
    // 列数ルール（完全決め打ち）
    // =========================
    final int crossAxisCount;
    if (!isTablet && !isLandscape) {
      // 📱 スマホ縦
      crossAxisCount = 1;
    } else if (!isTablet && isLandscape) {
      // 📱 スマホ横
      crossAxisCount = 2;
    } else if (isTablet && !isLandscape) {
      // 📲 iPad縦
      crossAxisCount = 2;
    } else {
      // 📲 iPad横
      crossAxisCount = 3;
    }

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];
            final rank = index + 1;

            return VideoOverlayCard(
              video: video,
              rank: rank,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childAspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
