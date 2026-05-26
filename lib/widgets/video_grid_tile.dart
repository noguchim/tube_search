import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tube_search/utils/rank_badge.dart';

import '../data/youtube_video.dart';
import '../services/expanded_video_controller.dart';
import 'new_video_badge.dart';

class VideoGridTile extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;
  final VoidCallback onTap;
  final bool showNewBadge;
  final VideoPresentationMode presentationMode;

  const VideoGridTile({
    super.key,
    required this.video,
    required this.rank,
    required this.onTap,
    this.showNewBadge = false,
    this.presentationMode = VideoPresentationMode.ranked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final thumbnail = video.thumbnailUrl;
    final showRankingInfo = presentationMode == VideoPresentationMode.ranked;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/no_image.png',
                      fit: BoxFit.cover,
                    ),
                    fadeInDuration: const Duration(milliseconds: 200),
                  )
                : Image.asset(
                    'assets/images/no_image.png',
                    fit: BoxFit.cover,
                  ),
          ),
          if (showNewBadge || showRankingInfo)
            Positioned(
              top: 8,
              left: 8,
              child: showNewBadge
                  ? const NewVideoBadge()
                  : rankBadge(context, rank),
            ),
        ],
      ),
    );
  }
}
