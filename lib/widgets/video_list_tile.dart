import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../screens/shop_screen.dart';
import '../screens/video_player_screen.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../utils/favorite_delete_helper.dart';
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

    // 🎨 カード色・枠線は Theme 側を基準としつつ、より視認性を上げる BorderSide を追加
    final cardColor =
        theme.cardTheme.color ?? (isDark ? Colors.white10 : Colors.white);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07) // ← 0.05 → 0.07 に調整
            : Colors.black.withValues(alpha: 0.05),
        width: 1,
      ),
    );

    final elevation = theme.cardTheme.elevation ?? 0;

    final id = video['id'] ?? "";
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText =
        _formatViewCount(context, (video['viewCount'] ?? '0').toString());
    final isFav = fav.isFavoriteSync(id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Material(
        color: cardColor,
        shape: shape,
        elevation: elevation,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  video: video,
                  isRepeat: false,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- サムネイル ----------------
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,

                      // ✔ 以前取得していれば、オフラインでも表示される
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),

                      // ✔ 未取得 & オフライン → デザイン崩さず fallback
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[300],
                        child: const Icon(
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
                    child: _buildRankBadge(context, isDark),
                  ),
                ],
              ),

              // ---------------- 情報部分 ----------------
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // タイトル
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // チャンネル名
                    Text(
                      channel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54, // ← 改善
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ❤️ + 再生数
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6), // ← 少し右に寄せる
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final fav = context.read<FavoritesService>();
                              final iap = context.read<IapProvider>();

                              final isFavNow = fav.isFavoriteSync(id);

                              // ❤️ 解除（トグル）
                              if (isFavNow) {
                                await FavoriteDeleteHelper.confirmOrDelete(
                                    context, video);
                                return;
                              }

                              // 🔥 上限チェック付きで追加
                              final ok =
                                  await fav.tryAddFavorite(id, video, iap);

                              if (!ok) {
                                _showLimitDialog(context, iap);
                              }
                            },
                            child: AnimatedScale(
                              scale: isFav ? 1.18 : 1.0, // ← 視覚的に大きめアニメ
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
                                size: isFav ? 30 : 28, // ← 非活性でも大きめ & 活性は少し大きい
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 18), // ← バランス調整

                        Expanded(
                          child: Text(
                            viewText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
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
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface, // ← ★本文と同色
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
                  Navigator.pop(context); // ダイアログ閉じる
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

  /// Rankバッジ（よりガラスUIに寄せた改善版）
  Widget _buildRankBadge(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final rank = this.rank;

    Color baseColor;
    Color textColor;
    Border? border;

    if (rank == 1) {
      // 1位はブランドカラー
      baseColor = theme.colorScheme.primary;
      textColor = Colors.white;
      border = null;
    } else if (rank == 2 || rank == 3) {
      // 2位・3位 → 白透明 0.10 のガラス風
      baseColor = isDark ? const Color(0xFF333333) : Colors.white;
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.2);
    } else {
      // 4位以降 → 白透明 0.12（少し濃いめ）
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
