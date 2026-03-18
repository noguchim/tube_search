import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/video_grid_tile.dart';
import 'package:tube_search/widgets/video_list_tile.dart';

import '../data/youtube_video.dart';
import '../services/expanded_video_controller.dart';

class PopularBigSection extends StatelessWidget {
  final List<YouTubeVideo> videos;

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
    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool isTablet = media.size.shortestSide >= 600;

    final bool useHorizontalLayout = isLandscape;

    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    final topVideo = videos.first;
    final restVideos = videos.skip(1).toList();

    final double horizontalPadding = isTablet ? 20 : 12;
    final bool useWidthConstraint =
        !isTablet && media.orientation == Orientation.portrait;

    final Widget content = useHorizontalLayout
        // =====================================================
        // 横向き（スマホ / iPad）
        // =====================================================
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isTablet ? 4 : 5,
                  child: VideoListTile(
                    video: topVideo,
                    rank: 1,
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),
                Expanded(
                  flex: isTablet ? 6 : 5,
                  child: _BigGrid(
                    videos: restVideos,
                    isTablet: isTablet,
                  ),
                ),
              ],
            ),
          )
        // =====================================================
        // 縦向き（スマホ / iPad）
        // =====================================================
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: VideoListTile(
                  video: topVideo,
                  rank: 1,
                ),
              ),
              if (restVideos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _BigGrid(
                    videos: restVideos,
                    isTablet: isTablet,
                  ),
                ),
            ],
          );

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          useWidthConstraint ? SliverWidthContainer(child: content) : content,
        ],
      ),
    );
  }
}

class SliverWidthContainer extends StatelessWidget {
  final Widget child;

  const SliverWidthContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600, // スマホ縦専用
        ),
        child: child,
      ),
    );
  }
}

class _BigGrid extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool isTablet;

  const _BigGrid({
    required this.videos,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = isTablet ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
  }
}
