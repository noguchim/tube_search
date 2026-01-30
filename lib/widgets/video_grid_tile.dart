import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tube_search/utils/rank_badge.dart';

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
      behavior: HitTestBehavior.opaque, // ← 隙間タップ防止
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand, // ← マスを完全に埋める
        children: [
          // ===============================
          // 🎞 サムネ
          // ===============================
          ClipRRect(
            borderRadius: BorderRadius.circular(6), // ← ここを 4〜6 で微調整
            child: thumbOk
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
          ),

          // ===============================
          // 🏷 Rankバッジ
          // ===============================
          Positioned(
            top: 8,
            left: 8,
            child: rankBadge(context, rank),
          ),
        ],
      ),
    );
  }
}
