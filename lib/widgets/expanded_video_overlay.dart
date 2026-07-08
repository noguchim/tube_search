import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/data/youtube_video.dart';
import 'package:tube_search/widgets/play_button_overlay.dart';
import 'package:tube_search/widgets/popularity_chip.dart';

import '../providers/recommendation_history_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/watch_history_service.dart';
import '../utils/format_util.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/ui_scale.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';
import 'live_badge.dart';

class ExpandedVideoOverlay extends StatelessWidget {
  final YouTubeVideo video;
  final int rank;
  final VoidCallback onClose;

  const ExpandedVideoOverlay({
    super.key,
    required this.video,
    required this.rank,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;

    final bool isTablet = shortest >= 600;
    final bool isLargeTablet = shortest >= 900;

    final double maxWidth = isLargeTablet
        ? 700
        : isTablet
            ? 440
            : 360;

    final double maxHeight = isLargeTablet
        ? 530
        : isTablet
            ? 400
            : 335;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            // ===============================
            // 🔥 背景タップ検知レイヤー
            // ===============================
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onClose,
              ),
            ),

            // ===============================
            // カード本体（中央）
            // ===============================
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: ExpandedVideoCard(
                  video: video,
                  onClose: onClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandedVideoCard extends StatefulWidget {
  final YouTubeVideo video;
  final VoidCallback onClose;

  const ExpandedVideoCard({
    super.key,
    required this.video,
    required this.onClose,
  });

  @override
  State<ExpandedVideoCard> createState() => _ExpandedVideoCardState();
}

class _ExpandedVideoCardState extends State<ExpandedVideoCard>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();
    final history = context.watch<WatchHistoryService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final Color cardColor = theme.colorScheme.surface;

    final video = widget.video;
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
    final isWatched = history.isWatchedSync(id);
    final titleColor =
        isWatched ? onSurface.withValues(alpha: 0.46) : onSurface;
    final borderRadius = BorderRadius.circular(16);

    final controller = context.watch<ExpandedVideoController>();
    final showRankingInfo =
        controller.presentationMode == VideoPresentationMode.ranked;

    bool isTaping = false;

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

    Future<void> pushPlayer() async {
      if (isTaping) return;
      isTaping = true;
      try {
        final id = video.id;
        if (id.isEmpty) return;
        await openYouTubeInInAppBrowser(context, videoId: id);
      } finally {
        isTaping = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // サムネ（タップで再生）
              // =================================================
              Material(
                color: Colors.transparent,
                child: InkWell(
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
                  borderRadius: borderRadius,
                  child: Ink(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: thumbnail.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumbnail,
                                    fit: BoxFit.cover,
                                    width: double.infinity,

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

                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                  )
                                : Image.asset(
                                    'assets/images/no_image.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          ),

                          // 🎬 中央再生ボタン（Overlay最適サイズ）
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: PlayButtonOverlay(
                                  sizeOverride: 40, // ← Overlayは大きめがUX最強
                                ),
                              ),
                            ),
                          ),

                          // 🔥 投稿日/動画時間
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(4),
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

                          Positioned(
                            top: 8,
                            right: 8,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: widget.onClose,
                                  child: const Center(
                                    child: Icon(
                                      Icons.unfold_less,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // =================================================
              // 情報部
              // =================================================
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // タイトル
                    // =========================
                    SizedBox(
                      height: 40,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.35,
                          color: titleColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =========================
                    // チャンネル名
                    // =========================
                    Text(
                      channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurface,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // =========================
                    // 再生数 + ❤️（同一行Stack）
                    // =========================
                    Stack(
                      alignment: Alignment.centerRight,
                      clipBehavior: Clip.none, // ← まず必須
                      children: [
                        // 再生数（高さ基準）
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
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

                        // ❤️
                        Positioned(
                          left: -10,
                          bottom: -22, // 少し下に逃がす
                          child: FavoriteButtonOverlay(
                            key: ValueKey('expanded_favorite_${video.id}'),
                            isFavorite: isFav,
                            showBackground: false,
                            scale: 1.25,
                            onTap: () => handleFavoriteTap(
                              context,
                              video: video,
                            ),
                          ),
                        ),
                      ],
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
