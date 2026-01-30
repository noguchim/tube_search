import 'package:flutter/material.dart';

import '../widgets/video_overlay_card.dart';

class PopularMiddleSection extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const PopularMiddleSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    final double shortest = media.size.shortestSide;
    final bool isPhone = shortest < 600;

    const double mainSpacing = 0;
    const double crossSpacing = 0;

    final double maxTileWidth = shortest >= 900 ? 360 : 320;

    SliverGridDelegate gridDelegate;

    if (isPhone && !isLandscape) {
      // 📱 Phone 縦：1列
      gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
    } else if (isPhone && isLandscape) {
      // 📱 Phone 横：2列
      gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
    } else {
      // 📲 Tablet / 大画面
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxTileWidth,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 16 / 9,
      );
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
        gridDelegate: gridDelegate,
      ),
    );
  }
}
