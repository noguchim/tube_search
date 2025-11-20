import 'package:flutter/material.dart';
import '../screens/video_player_screen.dart';

class VideoListTile extends StatefulWidget {
  final Map<String, dynamic> video;
  final int rank; // ⭐ ランキング番号

  const VideoListTile({
    super.key,
    required this.video,
    required this.rank,
  });

  @override
  State<VideoListTile> createState() => _VideoListTileState();
}

class _VideoListTileState extends State<VideoListTile> {
  bool _isPressed = false;
  bool _isLoading = false;

  // ⭐ 再生数を「万回」表記に変換
  String _formatViewCount(String value) {
    final num? number = num.tryParse(value);
    if (number == null) return '0回視聴';

    if (number < 10000) {
      // 1万未満 → そのまま
      return '${number.toInt()}回視聴';
    } else if (number < 100000000) {
      // 万単位（1万〜9999万）
      final double man = number / 10000;
      final formatted = man.toStringAsFixed(man < 10 ? 1 : 0); // 1桁は小数1位
      return '$formatted万回視聴';
    } else {
      // 億単位も念のため対応
      final double oku = number / 100000000;
      final formatted = oku.toStringAsFixed(1);
      return '$formatted億回視聴';
    }
  }

  Future<void> _navigateToPlayer(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            video: widget.video,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final title = video['title'] ?? '';
    final thumbnail = video['thumbnailUrl'] ?? '';
    final channel = video['channelTitle'] ?? '';
    final viewText = _formatViewCount((video['viewCount'] ?? '0').toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Stack(
        children: [
          AnimatedScale(
            scale: _isPressed ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.grey.withValues(alpha: _isPressed ? 0.5 : 0.25),
                    blurRadius: _isPressed ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapCancel: () => setState(() => _isPressed = false),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTap: () => _navigateToPlayer(context),
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),

                        // ⭐ メタリック光沢ランキングバッジ
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Builder(
                            builder: (context) {
                              final theme = Theme.of(context);
                              final rank = widget.rank;

                              // 背景色・文字色・枠線設定
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
                                border = Border.all(color: Colors.grey.shade400, width: 1.2);
                              }

                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: border,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 5,
                                      offset: const Offset(1, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // 💡 上部ハイライト（反射光）
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withValues(alpha: 0.55),
                                                Colors.white.withValues(alpha: 0.15),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.25, 0.7],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 🌫️ 下部影の帯
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.08),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.7],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 🏅 ランク数字（中央）
                                    Center(
                                      child: Text(
                                        "$rank",
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          height: 1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // ---------------- 情報部分 ----------------
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            channel,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewText, // ← 「XX万回視聴」形式で表示
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
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

          // ---------------- ローディングインジケーター ----------------
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
