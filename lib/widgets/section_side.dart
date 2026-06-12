import 'package:flutter/material.dart';

import '../data/youtube_video.dart';
import 'video_list_side.dart';

class SectionSide extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool Function(YouTubeVideo video)? isNewVideo;
  final ValueChanged<YouTubeVideo>? onVideoTap;
  final bool asSliver;
  final bool showPopularityScore;
  final bool showRankBadge;

  const SectionSide({
    super.key,
    required this.videos,
    this.isNewVideo,
    this.onVideoTap,
    this.asSliver = true,
    this.showPopularityScore = true,
    this.showRankBadge = true,
  });

  bool _isNew(YouTubeVideo video) {
    return isNewVideo?.call(video) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return asSliver
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isTablet = media.size.shortestSide >= 600;
    final crossAxisCount = (isLandscape || isTablet) ? 2 : 1;

    if (!asSliver) {
      if (crossAxisCount == 1) {
        return Column(
          children: List.generate(videos.length, (index) {
            final video = videos[index];

            return VideoListSide(
              video: video,
              rank: showRankBadge ? index + 1 : null,
              showNewBadge: _isNew(video),
              showPopularityScore: showPopularityScore,
              onVideoTap: onVideoTap,
            );
          }),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: videos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 116,
          mainAxisSpacing: 6,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final video = videos[index];

          return VideoListSide(
            video: video,
            rank: showRankBadge ? index + 1 : null,
            showNewBadge: _isNew(video),
            showPopularityScore: showPopularityScore,
            onVideoTap: onVideoTap,
          );
        },
      );
    }

    if (crossAxisCount == 1) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];

            return VideoListSide(
              video: video,
              rank: showRankBadge ? index + 1 : null,
              showNewBadge: _isNew(video),
              showPopularityScore: showPopularityScore,
              onVideoTap: onVideoTap,
            );
          },
          childCount: videos.length,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];

            return VideoListSide(
              video: video,
              rank: showRankBadge ? index + 1 : null,
              showNewBadge: _isNew(video),
              showPopularityScore: showPopularityScore,
              onVideoTap: onVideoTap,
            );
          },
          childCount: videos.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 116,
          mainAxisSpacing: 6,
          crossAxisSpacing: 4,
        ),
      ),
    );
  }
}
