import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/favorites_service.dart';
import '../utils/app_logger.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/rank_badge.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';

/// 🥇 1位専用：Top Rank（フラット版・カード不使用）
class VideoListTopRank extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;

  const VideoListTopRank({
    super.key,
    required this.video,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortestSide = media.size.shortestSide;
    final isLandscape = media.orientation == Orientation.landscape;

    final bool isTablet = shortestSide >= 600;

    // =================================================
    // 📐 TopRank 専用マージン（端末差吸収ポイント）
    // =================================================
    final EdgeInsets outerPadding = EdgeInsets.fromLTRB(
      isTablet ? 20 : 12,
      isLandscape ? 12 : 8,
      isTablet ? 20 : 12,
      0,
    );

    final fav = context.watch<FavoritesService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final id = video['id'] ?? '';
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText =
        formatViewCount(context, (video['viewCount'] ?? '0').toString());

    final isFav = fav.isFavoriteSync(id);

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

    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

    return Padding(
      padding: outerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================
          // 🎥 サムネ（ヒーロー）
          // =================================================
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10), // ← 角丸
            clipBehavior: Clip.antiAlias, // ← これが超重要
            child: InkWell(
              onTap: pushPlayer,
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: thumbOk
                        ? Ink.image(
                            image: CachedNetworkImageProvider(thumbnail),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            child: const SizedBox.expand(),
                          )
                        : Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.wifi_off_rounded,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IgnorePointer(
                      child: rankBadge(context, rank),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // =================================================
          // 📝 情報部（フラット・高さ安定版）
          // =================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------
              // タイトル（左寄せ）
              // -------------------------
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),

              const SizedBox(height: 4),

              // -------------------------
              // チャンネル名（右寄せ）
              // -------------------------
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  channel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // -------------------------
              // ❤️ + 再生数（Stack）
              // -------------------------
              SizedBox(
                height: 28, // ← ★高さ固定（縦横共存の要）
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 12,
                      bottom: 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => handleFavoriteTap(
                          context,
                          video: video,
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: FavoriteButtonOverlay(
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

                    // 👁 再生数 右寄せ
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(
                        viewText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
