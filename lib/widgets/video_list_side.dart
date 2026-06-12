import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../providers/recommendation_history_provider.dart';
import '../services/favorites_service.dart';
import '../services/watch_history_service.dart';
import '../utils/format_util.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/rank_badge.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';
import 'new_video_badge.dart';
import 'popularity_chip.dart';

class VideoListSide extends StatelessWidget {
  final YouTubeVideo video;
  final int? rank;
  final bool showNewBadge;
  final bool showPopularityScore;
  final ValueChanged<YouTubeVideo>? onVideoTap;

  const VideoListSide({
    super.key,
    required this.video,
    this.rank,
    this.showNewBadge = false,
    this.showPopularityScore = true,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fav = context.watch<FavoritesService>();
    final history = context.watch<WatchHistoryService>();
    final isFav = fav.isFavoriteSync(video.id);
    final isWatched = history.isWatchedSync(video.id);
    final titleColor = isWatched
        ? theme.colorScheme.onSurface.withValues(alpha: 0.46)
        : theme.colorScheme.onSurface;
    final titleChannelGap = showPopularityScore ? 8.0 : 8.0;
    final channelMetaGap = showPopularityScore ? 8.0 : 6.0;

    final duration =
        (video.durationSeconds != null && video.durationSeconds! > 0)
            ? formatDuration(video.durationSeconds!)
            : null;
    final viewText = formatViewCount(
      context,
      (video.viewCount ?? 0).toString(),
      format: ViewCountFormat.compact,
    );
    final timeAgo = formatPublishedAgo(context, video.publishedAt);
    final metaText = '$viewText${separator(context)}$timeAgo';

    bool isPushing = false;

    Future<void> pushPlayer() async {
      if (isPushing) return;
      isPushing = true;
      try {
        if (video.id.isEmpty) return;
        await openYouTubeInInAppBrowser(context, videoId: video.id);
      } finally {
        isPushing = false;
      }
    }

    Future<void> handleTap() async {
      onVideoTap?.call(video);
      context.read<WatchHistoryService>().add(video);
      unawaited(
        context.read<RecommendationHistoryProvider>().recordVideoTap(
              videoId: video.id,
              title: video.title,
              channelId: video.channelId,
              channelTitle: video.channelTitle,
            ),
      );
      await pushPlayer();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbWidth = width < 360 ? 150.0 : 165.0;
        final thumbHeight = width < 360 ? 90.0 : 100.0;
        final radius = BorderRadius.circular(8);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: radius,
                    child: SizedBox(
                      width: thumbWidth,
                      height: thumbHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          video.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[300],
                                  ),
                                  errorWidget: (_, __, ___) => Image.asset(
                                    'assets/images/no_image.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/no_image.png',
                                  fit: BoxFit.cover,
                                ),
                          if (duration != null)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: _DurationPill(duration: duration),
                            ),
                          Positioned(
                            top: 0,
                            right: -2,
                            child: FavoriteButtonOverlay(
                              key: ValueKey('side_favorite_${video.id}'),
                              isFavorite: isFav,
                              showBackground: true,
                              scale: 0.9,
                              onTap: () => handleFavoriteTap(
                                context,
                                video: video,
                              ),
                            ),
                          ),
                          if (showNewBadge)
                            const Positioned(
                              top: 6,
                              left: 6,
                              child: IgnorePointer(
                                child: NewVideoBadge(),
                              ),
                            )
                          else if (rank != null)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: IgnorePointer(
                                ignoring: true,
                                child: rankBadge(context, rank!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: thumbHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.18,
                              color: titleColor,
                            ),
                          ),
                          SizedBox(height: titleChannelGap),
                          Text(
                            video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: channelMetaGap),
                          Row(
                            children: [
                              if (showPopularityScore) ...[
                                PopularityChip(
                                  popularity: video.popularity,
                                  fontSize: 15,
                                  iconSize: 17,
                                  height: 25,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  metaText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DurationPill extends StatelessWidget {
  final String duration;

  const _DurationPill({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        duration,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
