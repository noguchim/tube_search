import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../screens/shop_screen.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../utils/app_logger.dart';
import '../utils/favorite_delete_helper.dart';
import '../utils/open_in_custom_tabs.dart';
import 'app_dialog.dart';

class VideoListTileMiddle extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;

  const VideoListTileMiddle({
    super.key,
    required this.video,
    required this.rank,
  });

  String _formatViewCount(BuildContext context, String value) {
    final num? number = num.tryParse(value);
    if (number == null) return '0';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ja') {
      if (number < 10000) {
        return '${number.toInt()}回視聴';
      } else if (number < 100000000) {
        final man = number / 10000;
        final formatted = man.toStringAsFixed(man < 10 ? 1 : 0);
        return '$formatted万回視聴';
      } else {
        final oku = number / 100000000;
        return '${oku.toStringAsFixed(1)}億回視聴';
      }
    }

    if (number < 1000) {
      return '${number.toInt()} views';
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K views';
    } else if (number < 1000000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M views';
    } else {
      return '${(number / 1000000000).toStringAsFixed(1)}B views';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 統一トーン
    final Color cardColor = theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;

    final BorderRadius borderRadius = BorderRadius.circular(12);

    final BorderSide borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      width: 1,
    );

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      if (isDark)
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
        _formatViewCount(context, (video['viewCount'] ?? '0').toString());
    final isFav = fav.isFavoriteSync(id);

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

    Future<void> toggleFav() async {
      final fav = context.read<FavoritesService>();
      final iap = context.read<IapProvider>();

      final isFavNow = fav.isFavoriteSync(id);

      if (isFavNow) {
        await FavoriteDeleteHelper.confirmOrDelete(context, video);
        return;
      }

      final ok = await fav.tryAddFavorite(id, video, iap);
      if (!ok) _showLimitDialog(context, iap);
    }

    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: borderRadius,
          border: Border.fromBorderSide(borderSide),
          boxShadow: shadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,

          // ✅ カード全体タップ禁止（誤タップ対策の本体）
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // ✅ サムネイルだけタップで再生
              // =========================================================
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: pushPlayer,
                  child: Ink(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: thumbOk
                              ? Ink.image(
                                  image: CachedNetworkImageProvider(thumbnail),
                                  fit: BoxFit.cover,
                                  child: const SizedBox.expand(),
                                )
                              : Container(
                                  color: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.wifi_off_rounded,
                                        size: 32, color: Colors.grey),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IgnorePointer(
                            ignoring: true,
                            child: _buildRankBadge(context, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- 情報部分（余白削減） ----------------
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // タイトル（2行に）
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: onSurface,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // チャンネル名
                    Text(
                      channel,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: onSurface.withValues(alpha: 0.72),
                      ),
                    ),

                    // const SizedBox(height: 4),

                    // ❤️ + 再生数
                    Row(
                      children: [
                        // ✅ 44x44のタップ領域（誤タップ激減）
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: InkResponse(
                            onTap: toggleFav,
                            radius: 24,
                            child: Center(
                              child: AnimatedScale(
                                scale: isFav ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? Colors.red
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.grey.shade600),
                                  size: isFav ? 26 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            viewText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: onSurface,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, IapProvider iap) {
    final purchased = iap.isPurchased(IapProducts.limitUpgrade.id);
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) {
        return AppDialog(
          title: t.favoriteLimitTitle,
          message: purchased
              ? t.favoriteLimitPurchased
              : t.favoriteLimitNotPurchased,
          style: AppDialogStyle.info,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: Text(t.favoriteLimitClose),
              onPressed: () => Navigator.pop(context),
            ),
            if (!purchased)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                },
                child: Text(t.favoriteLimitUpgrade),
              ),
            const SizedBox(width: 10),
          ],
        );
      },
    );
  }

  Widget _buildRankBadge(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final rank = this.rank;

    Color baseColor;
    Color textColor;
    Border? border;

    if (rank == 1) {
      baseColor = theme.colorScheme.primary;
      textColor = Colors.white;
      border = null;
    } else if (rank == 2 || rank == 3) {
      baseColor = isDark ? const Color(0xFF333333) : Colors.white;
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.2);
    } else {
      baseColor = isDark ? const Color(0xFF3A3A3A) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
      border = Border.all(
        color: isDark ? Colors.white24 : Colors.black26,
        width: 1.2,
      );
    }

    return Container(
      width: 38,
      height: 38, // ✅ 少し小さく
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Center(
        child: Text(
          "$rank",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}
