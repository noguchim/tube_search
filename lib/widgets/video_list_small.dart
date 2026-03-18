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

class VideoListTileSmall extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;

  const VideoListTileSmall({
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
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.07),
      width: 1,
    );

    final List<BoxShadow> shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ];

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    final id = video.id;
    final title = video.title;
    final thumbnail = video.thumbnailUrl;
    final channel = video.channelTitle;
    final viewText =
        formatViewCount(context, (video.viewCount ?? '0').toString());
    final isFav = fav.isFavoriteSync(id);

    const double thumbW = 136;
    const double thumbH = 76;
    bool isPushing = false;

    Future<void> pushPlayer() async {
      if (isPushing) return;
      isPushing = true;
      try {
        final id = video.id;
        logger.w("🚨 OPEN CCT id=$id");

        if (id.isEmpty) return;

        await openYouTubeInInAppBrowser(context, videoId: id);
      } finally {
        isPushing = false;
      }
    }

    final BorderRadius thumbRadius = BorderRadius.circular(6);
    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 2 : 5,
        horizontal: 8,
      ),
      child: SizedBox(
        // height: 115, // ← ★ Smallカードの確定高さ（調整可）
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

            // ✅ カード全体タップは禁止（誤タップ根絶）
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: isLandscape ? 6 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================================================
                  // ✅ サムネだけタップで再生
                  // =========================================================
                  Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: thumbRadius, // ← ★ これが決定打
                    ),
                    clipBehavior: Clip.antiAlias, // ← ★ 超重要
                    child: InkWell(
                      onTap: pushPlayer,
                      borderRadius: thumbRadius,
                      child: Ink(
                        child: ClipRRect(
                          borderRadius: thumbRadius,
                          child: Stack(
                            children: [
                              SizedBox(
                                width: thumbW,
                                height: thumbH,
                                child: thumbOk
                                    ? Ink.image(
                                        image: CachedNetworkImageProvider(
                                            thumbnail),
                                        fit: BoxFit.cover,
                                        child: const SizedBox.expand(),
                                      )
                                    : Container(
                                        color: isDark
                                            ? Colors.grey[850]
                                            : Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.wifi_off_rounded,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                              ),

                              // 🎯 Small専用：中央再生ボタン（安全配置）
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: PlayButtonOverlay(
                                      subtle: true,
                                      sizeOverride: 30, // ← Small最適サイズ（重要）
                                    ),
                                  ),
                                ),
                              ),

                              // Rank badge
                              Positioned(
                                top: 6,
                                left: 6,
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: rankBadge(context, rank),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ✅ 情報
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            color: onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // チャンネル
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withValues(alpha: 0.70),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ❤️ + 再生数
                        SizedBox(
                          height: 18, // ← 10 は小さすぎる。最低 18〜22
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -8,
                                bottom: -10,
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
                                        scale: 1.1,
                                        onTap: () => handleFavoriteTap(context,
                                            video: video),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    PopularityChip(
                                      popularity: video.popularity,
                                      fontSize: UIScale.font(context, 14),
                                      iconSize: UIScale.icon(context, 14),
                                      height: UIScale.height(context, 22),
                                    ),
                                    const SizedBox(width: 6),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        viewText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
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
      ),
    );
  }
}
