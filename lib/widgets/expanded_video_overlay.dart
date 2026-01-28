import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/favorites_service.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/view_count_formatter.dart';
import 'favorite_button_overlay.dart';

class ExpandedVideoOverlay extends StatelessWidget {
  final Map<String, dynamic> video;
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
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              // maxWidth: 360,
              // maxHeight: 460,
              maxWidth: 360,
              maxHeight: 330,
            ),
            child: ExpandedVideoCard(
              video: video,
              onClose: onClose, // ← 直呼び
            ),
          ),
        ),
      ),
    );
  }
}

class ExpandedVideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final Color cardColor = theme.colorScheme.surface;

    final video = widget.video;
    final id = video['id'] ?? '';
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText =
        formatViewCount(context, (video['viewCount'] ?? '0').toString());

    final isFav = fav.isFavoriteSync(id);
    final borderRadius = BorderRadius.circular(16);

    bool isPushing = false;

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
      if (isPushing) return;
      isPushing = true;
      try {
        final id = (video['id'] ?? '').toString();
        if (id.isEmpty) return;
        await openYouTubeInInAppBrowser(context, videoId: id);
      } finally {
        isPushing = false;
      }
    }

    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

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
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // サムネ（タップで再生）
              // =================================================
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
                                    child: const SizedBox.expand(),
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
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.unfold_less,
                                  size: 30,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onClose,
                                tooltip: 'Collapse',
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
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),

                    // =========================
                    // チャンネル名
                    // =========================
                    Text(
                      channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.72),
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
                          // ❤️の下方向分だけ余白を確保
                          padding: const EdgeInsets.only(left: 44),
                          child: Text(
                            viewText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                        ),

                        // ❤️
                        Positioned(
                          left: -10,
                          bottom: -22, // 少し下に逃がす
                          child: FavoriteButtonOverlay(
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
