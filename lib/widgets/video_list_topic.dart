import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/play_button_overlay.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/recommendation_history_provider.dart';
import '../services/favorites_service.dart';
import '../services/watch_history_service.dart';
import '../utils/app_logger.dart';
import '../utils/format_util.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';

class VideoListTopic extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;
  final bool showNewBadge;

  const VideoListTopic({
    super.key,
    required this.video,
    required this.rank,
    this.showNewBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();
    final history = context.watch<WatchHistoryService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor =
        isDark ? const Color(0xFF282828) : theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;

    final BorderRadius borderRadius = BorderRadius.circular(12);

    final BorderSide borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.30)
          : Colors.black.withValues(alpha: 0.45),
      width: 1,
    );

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];

    final id = video.id;
    final title = video.title;
    final thumbnail = video.thumbnailUrl;
    final channel = video.channelTitle;
    final timeAgo = formatPublishedAgo(context, video.publishedAt?.toLocal());
    final viewText = formatViewCount(
      context,
      (video.viewCount ?? 0).toString(),
      format: ViewCountFormat.compact,
    );
    final viewAndTime = '$viewText${separator(context)}$timeAgo';

    final isFav = fav.isFavoriteSync(id);
    final isWatched = history.isWatchedSync(id);
    final titleColor =
        isWatched ? onSurface.withValues(alpha: 0.46) : onSurface;

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

    bool isPressed = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 270,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: borderRadius,
            border: Border.fromBorderSide(borderSide),
            boxShadow: shadows,
            // gradient: isDark
            //     ? LinearGradient(
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //         colors: [
            //           Colors.white.withValues(alpha: 0.02),
            //           Colors.transparent,
            //         ],
            //       )
            //     : null,
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

                                  if (showNewBadge)
                                    const Positioned(
                                      left: 8,
                                      top: 8,
                                      child: _NewVideoBadge(),
                                    ),

                                  // ▶ 再生ボタン
                                  PlayButtonOverlay(pressed: isPressed),

                                  // 🔥 再生数 + 投稿日
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.75),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            viewAndTime,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ❤️ お気に入り（サムネ右上）
                                  Positioned(
                                    top: 1,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => handleFavoriteTap(
                                        context,
                                        video: video,
                                      ),
                                      child: FavoriteButtonOverlay(
                                        key: ValueKey(
                                          'topic_favorite_${video.id}',
                                        ),
                                        isFavorite: isFav,
                                        showBackground: true,
                                        scale: 0.9,
                                        onTap: () => handleFavoriteTap(
                                          context,
                                          video: video,
                                        ),
                                      ),
                                    ),
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
                          fontSize: 13,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface,
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

class _NewVideoBadge extends StatelessWidget {
  const _NewVideoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fiber_manual_record,
            size: 8,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.newBadge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
