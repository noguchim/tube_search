import 'package:flutter/material.dart';

import '../widgets/video_list_small.dart';

class PopularSmallSection extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const PopularSmallSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    final bool isTablet = shortestSide >= 600;

    // =========================
    // 列数
    // =========================
    final int crossAxisCount = isTablet
        ? 3
        : isLandscape
            ? 2
            : 1;

    // =========================
    // 高さ（Smallは密度優先）
    // =========================
    final double tileHeight = isTablet
        ? 112
        : isLandscape
            ? 104
            : 128;

    // =========================
    // 縦 or Grid 切替
    // =========================
    if (!isLandscape && !isTablet) {
      // 📱 Phone 縦 → List
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return VideoListTileSmall(
              video: videos[index],
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
      );
    }

    // 📱 横 / 📲 Tablet → Grid
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return VideoListTileSmall(
              video: videos[index],
              rank: index + 1,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: tileHeight,
          mainAxisSpacing: isLandscape ? 4 : 6,
          crossAxisSpacing: isLandscape ? 4 : 6,
        ),
      ),
    );
  }
}
