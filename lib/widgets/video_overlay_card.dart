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

class VideoOverlayCard extends StatelessWidget {
  final Map<String, dynamic> video;
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: pushPlayer,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // =====================================================
                  // ① サムネイル
                  // =====================================================
                  Positioned.fill(
                    child: thumbOk
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
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

                  // =====================================================
                  // ② 下部だけに限定（全体の約35%）グラデ（Amazon Prime方式）
                  // =====================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: MediaQuery.of(context).size.width * 9 / 16 * 0.35,
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
                  // ③ 情報オーバーレイ
                  // =====================================================
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _InfoOverlay(
                      title: title,
                      channel: channel,
                      viewText: viewText,
                    ),
                  ),

                  // =====================================================
                  // ④ Rankバッジ（既存維持）
                  // =====================================================
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IgnorePointer(
                      child: rankBadge(context, isDark, rank),
                    ),
                  ),

                  // ❤️ お気に入り（右上）
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButtonOverlay(
                      isFavorite: isFav,
                      onTap: () => handleFavoriteTap(
                        context,
                        video: video,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // 情報オーバーレイ部
  // =============================================================
  Widget _InfoOverlay({
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
