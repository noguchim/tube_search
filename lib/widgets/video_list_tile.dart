import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/play_button_overlay.dart';
import 'package:tube_search/widgets/popularity_chip.dart';

import '../data/youtube_video.dart';
import '../providers/recommendation_history_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/watch_history_service.dart';
import '../utils/app_logger.dart';
import '../utils/format_util.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/rank_badge.dart';
import '../utils/ui_scale.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';
import 'live_badge.dart';
import 'new_video_badge.dart';
import 'thumbnail_playback_progress.dart';

class VideoListTile extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;
  final bool showNewBadge;
  final VideoPresentationMode presentationMode;
  final ValueChanged<YouTubeVideo>? onVideoTap;

  const VideoListTile({
    super.key,
    required this.video,
    required this.rank,
    this.showNewBadge = false,
    this.presentationMode = VideoPresentationMode.ranked,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF202020)
        : theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;

    final BorderRadius borderRadius = BorderRadius.circular(12);

    final BorderSide borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.black.withValues(alpha: 0.05),
      width: 1,
    );

    final List<BoxShadow> shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.03),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ];

    final id = video.id;
    final title = video.title;
    final thumbnail = video.thumbnailUrl;
    final channel = video.channelTitle;
    final timeAgo = formatPublishedAgo(context, video.publishedAt);
    final duration =
        (video.durationSeconds != null && video.durationSeconds! > 0)
        ? formatDuration(video.durationSeconds!)
        : "--:--";

    final viewText = formatViewCount(
      context,
      (video.viewCount ?? 0).toString(),
      format: ViewCountFormat.full,
    );
    final timeAndDuration = '$timeAgo${separator(context)}$duration';

    final isFav = fav.isFavoriteSync(id);
    final titleColor = onSurface;

    final showRankingInfo = presentationMode == VideoPresentationMode.ranked;

    bool isTaping = false;

    Future<void> pushPlayer() async {
      if (isTaping) return;
      isTaping = true;
      try {
        if (id.isEmpty) return;
        logger.w("🚨 OPEN CCT id=$id");
        await openYouTubeInInAppBrowser(
          context,
          videoId: id,
          durationSeconds: video.durationSeconds,
        );
      } finally {
        isTaping = false;
      }
    }

    bool isPressed = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        // width: cardWidth,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: borderRadius,
            border: Border.fromBorderSide(borderSide),
            boxShadow: shadows,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.045),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,

            // ✅ ここでは InkWell を使わない（＝カード全体タップを禁止）
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- サムネイル（タップ領域：ここだけpush） ----------------
                Material(
                  color: Colors.transparent,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return InkWell(
                        onTap: () {
                          onVideoTap?.call(video);
                          context.read<WatchHistoryService>().add(video);
                          unawaited(
                            context
                                .read<RecommendationHistoryProvider>()
                                .recordVideoTap(
                                  videoId: video.id,
                                  title: video.title,
                                  channelId: video.channelId,
                                  channelTitle: video.channelTitle,
                                ),
                          );
                          pushPlayer();
                        },
                        onTapDown: (_) => setState(() => isPressed = true),
                        onTapUp: (_) => setState(() => isPressed = false),
                        onTapCancel: () => setState(() => isPressed = false),
                        borderRadius: borderRadius,
                        child: Ink(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // ---------------- サムネ（改善版） ----------------
                                  Positioned.fill(
                                    child: thumbnail.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: thumbnail,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                Image.asset(
                                                  'assets/images/no_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                          )
                                        : Image.asset(
                                            'assets/images/no_image.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),

                                  // ▶ 再生ボタン
                                  PlayButtonOverlay(pressed: isPressed),

                                  // 🔥 投稿日/動画時間
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.75,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            timeAndDuration,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (video.isLive)
                                    const Positioned(
                                      left: 8,
                                      bottom: 8,
                                      child: IgnorePointer(
                                        child: LiveBadge(
                                          fontSize: 14,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          backgroundColor: Color(0xFFF57C00),
                                        ),
                                      ),
                                    ),

                                  if (showNewBadge || showRankingInfo)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: IgnorePointer(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showNewBadge)
                                              const NewVideoBadge()
                                            else if (showRankingInfo)
                                              rankBadge(context, rank),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ThumbnailPlaybackProgress(
                                    videoId: video.id,
                                    durationSeconds: video.durationSeconds,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // =========================================================
                // ✅ 情報部分はタップしても再生しない
                // =========================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, color: onSurface),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 28,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              bottom: -8,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    handleFavoriteTap(context, video: video),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: FavoriteButtonOverlay(
                                      key: ValueKey(
                                        'tile_favorite_${video.id}',
                                      ),
                                      isFavorite: isFav,
                                      showBackground: false,
                                      scale: 1.2,
                                      onTap: () => handleFavoriteTap(
                                        context,
                                        video: video,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  if (showRankingInfo)
                                    PopularityChip(
                                      popularity: video.popularity,
                                      fontSize: UIScale.font(context, 18),
                                      iconSize: UIScale.icon(context, 18),
                                      height: UIScale.height(context, 24),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    viewText,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
