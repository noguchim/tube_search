import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tube_search/utils/rank_badge.dart';

import '../data/youtube_video.dart';

class VideoGridTile extends StatelessWidget {
  final YouTubeVideo video;
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

    final thumbnail = video.thumbnailUrl;
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
            borderRadius: BorderRadius.circular(6),
            child: thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,

                    // 読み込み中
                    placeholder: (_, __) => Container(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                    ),

                    // エラー時（統一）
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/no_image.png',
                      fit: BoxFit.cover,
                    ),

                    fadeInDuration: const Duration(milliseconds: 200),
                  )
                : Image.asset(
                    'assets/images/no_image.png',
                    fit: BoxFit.cover,
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
