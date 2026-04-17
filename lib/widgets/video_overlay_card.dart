import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/widgets/play_button_overlay.dart';
import 'package:tube_search/widgets/popularity_chip.dart';

import '../data/youtube_video.dart';
import '../services/favorites_service.dart';
import '../utils/app_logger.dart';
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
    final viewText = formatViewCount(
      context,
      (video.viewCount ?? 0).toString(),
      format: ViewCountFormat.full,
    );

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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isPressed = false;

              return InkWell(
                onTap: pushPlayer,
                onTapDown: (_) => setState(() => isPressed = true),
                onTapUp: (_) => setState(() => isPressed = false),
                onTapCancel: () => setState(() => isPressed = false),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      // =====================================================
                      // ① サムネイル（既存そのまま）
                      // =====================================================
                      Positioned.fill(
                        child: thumbOk
                            ? Ink.image(
                                image: CachedNetworkImageProvider(thumbnail),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.wifi_off_rounded,
                                    size: 36,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ),

                      // 🆕 ② 中央再生ボタン（Overlay密度：標準強調）
                      PlayButtonOverlay(
                        pressed: isPressed,
                        sizeOverride: 42,
                        // Overlayは主役なので subtle: false（デフォルト）
                      ),

                      // =====================================================
                      // ③ 下部グラデ（既存）
                      // =====================================================
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height:
                            MediaQuery.of(context).size.width * 9 / 16 * 0.35,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x40000000),
                                Color(0x99000000),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // =====================================================
                      // ④ 情報オーバーレイ（既存）
                      // =====================================================
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: infoOverlay(
                          title: title,
                          channel: channel,
                          viewText: viewText,
                        ),
                      ),

                      // Rank
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

                      // ❤️ お気に入り（既存）
                      Positioned(
                        top: 0,
                        right: 4,
                        child: FavoriteButtonOverlay(
                          isFavorite: isFav,
                          scale: 1.1,
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
  // 情報オーバーレイ部
  // =============================================================
  Widget infoOverlay({
    required String title,
    required String channel,
    required String viewText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '$channel ・ $viewText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
