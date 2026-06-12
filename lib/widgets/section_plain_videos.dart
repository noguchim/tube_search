import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/video_grid_tile.dart';
import 'package:tube_search/widgets/video_list_tile.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../services/expanded_video_controller.dart';

class SectionPlainVideos extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool Function(YouTubeVideo video)? isNewVideo;
  final ValueChanged<YouTubeVideo>? onVideoTap;
  final bool showRelatedTitle;
  final String relatedTitle;

  const SectionPlainVideos({
    super.key,
    required this.videos,
    this.isNewVideo,
    this.onVideoTap,
    this.showRelatedTitle = false,
    this.relatedTitle = "",
  });

  Widget _buildRelatedTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 1.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isNew(YouTubeVideo video) {
    return isNewVideo?.call(video) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final l = AppLocalizations.of(context)!;
    final isTablet = media.size.shortestSide >= 600;
    final topVideo = videos.first;
    final restVideos = videos.skip(1).toList();
    final shouldShowRelatedTitle = showRelatedTitle && restVideos.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: VideoListTile(
            video: topVideo,
            rank: 1,
            showNewBadge: _isNew(topVideo),
            presentationMode: VideoPresentationMode.plain,
            onVideoTap: onVideoTap,
          ),
        ),
        if (shouldShowRelatedTitle)
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: _buildRelatedTitle(
              context,
              relatedTitle.isEmpty ? l.relatedVideos : relatedTitle,
            ),
          ),
        if (restVideos.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: shouldShowRelatedTitle ? 20 : 14,
            ),
            child: _PlainGrid(
              videos: restVideos,
              isTablet: isTablet,
              isNewVideo: isNewVideo,
              onVideoTap: onVideoTap,
            ),
          ),
      ],
    );
  }
}

class _PlainGrid extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool isTablet;
  final bool Function(YouTubeVideo video)? isNewVideo;
  final ValueChanged<YouTubeVideo>? onVideoTap;

  const _PlainGrid({
    required this.videos,
    required this.isTablet,
    required this.isNewVideo,
    required this.onVideoTap,
  });

  bool _isNew(YouTubeVideo video) {
    return isNewVideo?.call(video) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = isTablet ? 3 : 2;
    final controller = context.read<ExpandedVideoController>();

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
          showNewBadge: _isNew(video),
          presentationMode: VideoPresentationMode.plain,
          onTap: () {
            onVideoTap?.call(video);
            Feedback.forTap(context);

            controller.open(
              video,
              rank,
              presentationMode: VideoPresentationMode.plain,
            );
          },
        );
      },
    );
  }
}
