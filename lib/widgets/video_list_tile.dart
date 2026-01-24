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

class VideoListTile extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;

  const VideoListTile({
    super.key,
    required this.video,
    required this.rank,
  });

  String _formatViewCount(BuildContext context, String value) {
    final num? number = num.tryParse(value);
    if (number == null) return '0';

    final locale = Localizations.localeOf(context).languageCode;

    // 🇯🇵 日本形式（万 / 億）
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

    // 🌎 英語形式（K / M / B）
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

    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                            top: 8,
                            right: 8,
                            child: IgnorePointer(
                              ignoring: true, // バッジが波紋を邪魔しない
                              child: _buildRankBadge(context, isDark),
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
                    // const SizedBox(height: 4),
                    Row(
                      children: [
                        // ✅ タップ領域を44x44に拡張（誤タップ防止の本命）
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: InkResponse(
                            onTap: () async {
                              final fav = context.read<FavoritesService>();
                              final iap = context.read<IapProvider>();

                              final isFavNow = fav.isFavoriteSync(id);

                              if (isFavNow) {
                                await FavoriteDeleteHelper.confirmOrDelete(
                                  context,
                                  video,
                                );
                                return;
                              }

                              final ok =
                                  await fav.tryAddFavorite(id, video, iap);

                              if (!ok) {
                                _showLimitDialog(context, iap);
                              }
                            },
                            radius: 24,
                            child: Center(
                              child: AnimatedScale(
                                scale: isFav ? 1.18 : 1.0,
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
                                  size: isFav ? 30 : 28,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
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

  /// Rankバッジ（既存維持）
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
      width: 40,
      height: 40,
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
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
