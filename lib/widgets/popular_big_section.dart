import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/video_grid_tile.dart';
import 'package:tube_search/widgets/video_list_top_rank.dart';

import '../services/expanded_video_controller.dart';

class PopularBigSection extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const PopularBigSection({
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

    final topVideo = videos.first;
    final restVideos =
        videos.length > 1 ? videos.sublist(1) : <Map<String, dynamic>>[];

    // =========================
    // Margin 定義（元コード完全維持）
    // =========================
    final double horizontalPadding = isTablet ? 20 : 12;
    final double bigCardTopPadding = isTablet
        ? 28
        : isLandscape
            ? 20
            : 0;

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          if (!isLandscape) ...[
            // =========================
            // 縦向き
            // =========================
            Padding(
              padding: EdgeInsets.only(top: bigCardTopPadding),
              child: VideoListTopRank(
                video: topVideo,
                rank: 1,
              ),
            ),
            if (restVideos.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -10),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: _BigGrid(videos: restVideos),
                ),
              ),
          ] else ...[
            // =========================
            // 横向き（2ペイン）
            // =========================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左：BigCard
                  Expanded(
                    flex: isTablet ? 4 : 3,
                    child: Padding(
                      padding: EdgeInsets.only(top: bigCardTopPadding),
                      child: VideoListTopRank(
                        video: topVideo,
                        rank: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 12),
                  // 右：Grid
                  Expanded(
                    flex: isTablet ? 6 : 5,
                    child: Padding(
                      padding: EdgeInsets.only(top: isTablet ? 8 : 0),
                      child: _BigGrid(videos: restVideos),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigGrid extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const _BigGrid({
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxCardWidth = 240;
        const double spacing = 12;

        int crossAxisCount =
            (constraints.maxWidth / (maxCardWidth + spacing)).floor();

        crossAxisCount = crossAxisCount.clamp(2, 6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (context, index) {
            final video = videos[index];
            final rank = index + 2;

            return VideoGridTile(
              video: video,
              rank: rank,
              onTap: () {
                context.read<ExpandedVideoController>().open(video, rank);
              },
            );
          },
        );
      },
    );
  }
}
