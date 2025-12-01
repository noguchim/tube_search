import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/video_player_screen.dart';
import '../services/favorites_service.dart';

class VideoListTile extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;

  const VideoListTile({
    super.key,
    required this.video,
    required this.rank,
  });

  // ⭐ 再生数 → 万・億表記
  String _formatViewCount(String value) {
    final num? number = num.tryParse(value);
    if (number == null) return '0回視聴';

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

  @override
  Widget build(BuildContext context) {
    /// Providerの状態を購読
    final fav = context.watch<FavoritesService>();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final id = video['id'] ?? "";
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText = _formatViewCount((video['viewCount'] ?? '0').toString());

    final isFav = fav.isFavoriteSync(id);

    // ----------------------------------------------------------
    // 🎨 Light / Dark による色切り替え
    // ----------------------------------------------------------
    final Color cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.25) : Colors.grey.withOpacity(0.25);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final Color channelColor = isDark ? Colors.grey.shade300 : Colors.black87;
    final Color favOffColor =
        isDark ? Colors.grey.shade300 : Colors.grey.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(video: video),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- サムネイル ----------------
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      thumbnail,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[300]),
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
                padding: const EdgeInsets.all(10),
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
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // チャンネル名
                    Text(
                      channel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: channelColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ❤️ と視聴数
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await fav.toggle(id, video);
                          },
                          child: AnimatedScale(
                            scale: isFav ? 1.25 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav ? Colors.red : favOffColor,
                              size: isFav ? 28 : 33,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            viewText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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

  // ⭐ ランクバッジ（Light/Dark対応）
  Widget _buildRankBadge(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final rank = this.rank;

    Color baseColor;
    Color textColor;
    Border? border;

    if (rank == 1) {
      // 1位はブランドカラーで統一
      baseColor = theme.colorScheme.primary;
      textColor = Colors.white;
      border = null;
    } else if (rank == 2 || rank == 3) {
      // 2〜3位は白ベース（Darkは少し暗めに）
      baseColor = isDark ? const Color(0xFF333333) : Colors.white;
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.2);
    } else {
      // 4位以降は目立ちすぎないように
      baseColor = isDark ? const Color(0xFF3A3A3A) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
      border = Border.all(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
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
