import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/favorites_service.dart';
import '../utils/app_logger.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';

class VideoListTileSmall extends StatelessWidget {
  final Map<String, dynamic> video;
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

    final id = video['id'] ?? "";
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText =
        formatViewCount(context, (video['viewCount'] ?? '0').toString());
    final isFav = fav.isFavoriteSync(id);

    const double thumbW = 136;
    const double thumbH = 76;
    bool isPushing = false;

    Future<void> pushPlayer() async {
      if (isPushing) return;
      isPushing = true;
      try {
        final id = (video['id'] ?? '').toString();
        logger.w("🚨 OPEN CCT id=$id");

        if (id.isEmpty) return;

        await openYouTubeInInAppBrowser(context, videoId: id);
      } finally {
        isPushing = false;
      }
    }

    final BorderRadius thumbRadius = BorderRadius.circular(8);
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

                              // ✅ Rank badge overlay（波紋を邪魔しないようにする）
                              Positioned(
                                top: 6,
                                left: 6,
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: _buildRankBadgeSmall(context, isDark),
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
                                left: 0,
                                bottom: -18,
                                child: FavoriteButtonOverlay(
                                  isFavorite: isFav,
                                  showBackground: false,
                                  scale: 1.1,
                                  onTap: () =>
                                      handleFavoriteTap(context, video: video),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
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

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: cardColor,
  //         borderRadius: borderRadius,
  //         border: Border.fromBorderSide(borderSide),
  //         boxShadow: shadows,
  //         gradient: isDark
  //             ? LinearGradient(
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //                 colors: [
  //                   Colors.white.withValues(alpha: 0.045),
  //                   Colors.transparent,
  //                 ],
  //               )
  //             : null,
  //       ),
  //       clipBehavior: Clip.antiAlias,
  //       child: Material(
  //         color: Colors.transparent,
  //
  //         // ✅ カード全体タップは禁止（誤タップ根絶）
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //           child: Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // =========================================================
  //               // ✅ サムネだけタップで再生
  //               // =========================================================
  //               Material(
  //                 color: Colors.transparent,
  //                 child: InkWell(
  //                   onTap: pushPlayer,
  //                   borderRadius: thumbRadius,
  //                   child: Ink(
  //                     child: ClipRRect(
  //                       borderRadius: thumbRadius,
  //                       child: Stack(
  //                         children: [
  //                           SizedBox(
  //                             width: thumbW,
  //                             height: thumbH,
  //                             child: thumbOk
  //                                 ? Ink.image(
  //                                     image:
  //                                         CachedNetworkImageProvider(thumbnail),
  //                                     fit: BoxFit.cover,
  //                                     child: const SizedBox.expand(),
  //                                   )
  //                                 : Container(
  //                                     color: isDark
  //                                         ? Colors.grey[850]
  //                                         : Colors.grey[300],
  //                                     child: const Center(
  //                                       child: Icon(
  //                                         Icons.wifi_off_rounded,
  //                                         size: 20,
  //                                         color: Colors.grey,
  //                                       ),
  //                                     ),
  //                                   ),
  //                           ),
  //
  //                           // ✅ Rank badge overlay（波紋を邪魔しないようにする）
  //                           Positioned(
  //                             top: 6,
  //                             left: 6,
  //                             child: IgnorePointer(
  //                               ignoring: true,
  //                               child: _buildRankBadgeSmall(context, isDark),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //
  //               const SizedBox(width: 10),
  //
  //               // ✅ 情報
  //               Expanded(
  //                 child: Column(
  //                   // mainAxisSize: MainAxisSize.min,
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   mainAxisSize: MainAxisSize.max,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       title,
  //                       maxLines: 2,
  //                       overflow: TextOverflow.ellipsis,
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w800,
  //                         height: 1.12,
  //                         color: onSurface,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 6),
  //
  //                     Align(
  //                       alignment: Alignment.centerRight,
  //                       child: Text(
  //                         channel,
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: onSurface.withValues(alpha: 0.70),
  //                         ),
  //                       ),
  //                     ),
  //                     // =========================
  //                     // ❤️ + 再生数
  //                     // =========================
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         FavoriteButtonOverlay(
  //                           isFavorite: isFav,
  //                           showBackground: false,
  //                           scale: 0.9,
  //                           onTap: () =>
  //                               handleFavoriteTap(context, video: video),
  //                         ),
  //                         Text(
  //                           viewText,
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.w800,
  //                             color: onSurface,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRankBadgeSmall(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final rank = this.rank;

    Color baseColor;
    Color textColor;
    Border? border;

    if (rank == 1) {
      // 1位：ブランドカラー
      baseColor = theme.colorScheme.primary;
      textColor = Colors.white;
      border = null;
    } else if (rank == 2 || rank == 3) {
      // 2〜3位：白＋primary枠
      // baseColor = isDark ? const Color(0xFF333333) : Colors.white;
      baseColor = Colors.white;
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.2);
    } else {
      // 4位以降：落ち着いたトーン
      // baseColor = isDark ? const Color(0xFF3A3A3A) : Colors.white;
      baseColor = Colors.white;
      // textColor = isDark ? Colors.white : Colors.black87;
      textColor = Colors.black87;
      border = Border.all(
        color: isDark ? Colors.white24 : Colors.black26,
        width: 1.2,
      );
    }

    // ✅ Small用サイズ（サムネに合う）
    return Container(
      width: 24,
      // 28 → 24 ✅小さく
      height: 24,
      // 28 → 24 ✅小さく
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(5), // 7 → 5 ✅角丸小さく
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14), // 0.18 → 0.14 ✅控えめ
            blurRadius: 5, // 6 → 5
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        "$rank",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 13, // 14 → 13 ✅少し小さく
          height: 1.0,
        ),
      ),
    );
  }
}
