import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/play_button_overlay.dart';
import 'package:tube_search/widgets/popularity_chip.dart';

import '../data/youtube_video.dart';
import '../providers/recommendation_history_provider.dart';
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

class VideoOverlayCard extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;

  const VideoOverlayCard({
    super.key,
    required this.video,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final id = video.id;
    final title = video.title;
    final thumbnail = video.thumbnailUrl;
    final channel = video.channelTitle;
    final timeAgo = formatPublishedAgo(context, video.publishedAt);
    final viewText = formatViewCount(
      context,
      (video.viewCount ?? 0).toString(),
      format: ViewCountFormat.compact,
    );

    final infoSeparator = '$viewText${separator(context)}$timeAgo';

    final isFav = fav.isFavoriteSync(id);
    final isWatched = context.watch<WatchHistoryService>().isWatchedSync(id);
    final overlayTitleColor =
        isWatched ? Colors.white.withValues(alpha: 0.46) : Colors.white;

    bool isPushing = false;

    Future<void> pushPlayer() async {
      if (isPushing) return;
      isPushing = true;
      try {
        if (id.isEmpty) return;
        logger.w("🚨 OPEN CCT id=$id");
        await openYouTubeInInAppBrowser(context, videoId: id);
      } finally {
        isPushing = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isPressed = false;

              return InkWell(
                onTap: () {
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
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: thumbnail.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumbnail,
                                fit: BoxFit.cover,

                                // 読み込み中
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[300],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),

                                // エラー時
                                errorWidget: (_, __, ___) => Image.asset(
                                  'assets/images/no_image.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/no_image.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                      // =====================================================
                      // ② 中央再生ボタン
                      // =====================================================
                      PlayButtonOverlay(
                        pressed: isPressed,
                        sizeOverride: 36,
                      ),

                      // =====================================================
                      // ③ 情報カード（NEW）
                      // =====================================================
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _infoCard(
                          title: title,
                          channel: channel,
                          viewAndTime: infoSeparator,
                          titleColor: overlayTitleColor,
                        ),
                      ),

                      // =====================================================
                      // Score
                      // =====================================================
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              rankBadge(context, rank),
                              const SizedBox(width: 6),
                              PopularityChip(
                                popularity: video.popularity,
                                fontSize: UIScale.font(context, 17),
                                iconSize: UIScale.icon(context, 17),
                                height: UIScale.height(context, 23),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // =====================================================
                      // ❤️ お気に入り
                      // =====================================================
                      Positioned(
                        top: 0,
                        right: 4,
                        child: FavoriteButtonOverlay(
                          key: ValueKey('overlay_favorite_${video.id}'),
                          isFavorite: isFav,
                          scale: 1.0,
                          onTap: () => handleFavoriteTap(
                            context,
                            video: video,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =============================================================
  // 情報カード（NEW UI）
  // =============================================================
  Widget _infoCard({
    required String title,
    required String channel,
    required String viewAndTime,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),

        // 👇 下だけ角丸にするとより自然（おすすめ）
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ).copyWith(color: titleColor),
          ),
          const SizedBox(height: 4),
          Text(
            channel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewAndTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
