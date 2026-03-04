import 'package:flutter/material.dart';

/// ▶ サムネ中央再生ボタン（共通・タップアニメ対応版）
/// - 全Tile共通（List / Grid / Overlay / Small）
/// - タップ時だけ拡大＋発光
/// - 中央完全固定（Stackにそのまま置くだけでOK）
/// - 審査安全（YouTube非模倣）
class PlayButtonOverlay extends StatelessWidget {
  final double? sizeOverride;
  final bool subtle;
  final bool pressed; // ← アニメトリガ

  const PlayButtonOverlay({
    super.key,
    this.sizeOverride,
    this.subtle = false,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // タップは下のInkWellに通す
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = MediaQuery.of(context).size.shortestSide;
          final base = _calcSize(constraints, shortestSide);

          final double size = sizeOverride ?? base;

          // 🎯 押下アニメ
          final double scale = pressed ? 1.14 : 1.0;
          final double opacity =
              subtle ? (pressed ? 0.44 : 0.30) : (pressed ? 0.58 : 0.40);

          final double iconSize = size * 0.52;

          return Center(
            // ← ★ これが中央固定の核心
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: opacity),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: pressed ? 0.26 : 0.14,
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: pressed ? 0.50 : 0.30,
                      ),
                      blurRadius: pressed ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _calcSize(BoxConstraints c, double deviceShortest) {
    final minSide = c.biggest.shortestSide;

    // 🔥 あなたのUI最適チューニング（やや小さめ）
    if (minSide <= 120) return 26; // Small
    if (minSide <= 180) return 32; // Grid
    if (deviceShortest < 600) return 44; // Phone List
    return 52; // Overlay / Tablet（64は大きすぎ）
  }
}
