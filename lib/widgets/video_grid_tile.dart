import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoGridTile extends StatelessWidget {
  final Map<String, dynamic> video;
  final int rank;
  final VoidCallback onTap;

  const VideoGridTile({
    super.key,
    required this.video,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final thumbnail = video['thumbnailUrl'] ?? '';
    final bool thumbOk = thumbnail.isNotEmpty && thumbnail.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ===============================
            // 🎞 Hero 対象は「サムネのみ」
            // ===============================
            Hero(
              tag: 'video-thumb-${video['id']}', // ← ★ videoIdベース
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbOk
                    ? CachedNetworkImage(
                        imageUrl: thumbnail,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
              ),
            ),

            // ===============================
            // 🏷 Rankバッジ（Hero対象外）
            // ===============================
            Positioned(
              top: 8,
              left: 8,
              child: _GridRankBadge(rank: rank),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridRankBadge extends StatelessWidget {
  final int rank;

  const _GridRankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color baseColor;
    Color textColor;
    Border? border;

    if (rank == 1) {
      baseColor = theme.colorScheme.primary;
      textColor = Colors.white;
      border = null;
    } else if (rank == 2 || rank == 3) {
      baseColor = Colors.white;
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.2);
    } else {
      baseColor = Colors.white;
      textColor = Colors.black87;
      border = Border.all(
        color: Colors.black26,
        width: 1.2,
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
