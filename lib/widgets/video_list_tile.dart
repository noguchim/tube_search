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

class VideoListTile extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;

  const VideoListTile({
    super.key,
    required this.video,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;

    final BorderRadius borderRadius = BorderRadius.circular(12);

    final BorderSide borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
      width: 1,
    );

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.55),
        blurRadius: 16,
        offset: const Offset(0, 10),
      ),
    ];

    final id = video['id'] ?? "";
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    Colors.white.withValues(alpha: 0.02),
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
                child: InkWell(
                  onTap: pushPlayer,
                  borderRadius: borderRadius,
                  child: Ink(
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: thumbOk
                                ? Ink.image(
                                    image:
                                        CachedNetworkImageProvider(thumbnail),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    child: const SizedBox.expand(), // Ink描画のため
                                  )
                                : Container(
                                    width: double.infinity,
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

                          // ✅ Rankバッジ
                          Positioned(
                            top: 10,
                            left: 10,
                            child: IgnorePointer(
                              ignoring: true, // バッジが波紋を邪魔しない
                              child: rankBadge(context, rank),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            bottom: -8,
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
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Text(
                              viewText,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
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
    );
  }
}
