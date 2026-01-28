import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FavoriteButtonOverlay extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final bool showBackground;
  final double scale;

  const FavoriteButtonOverlay({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.showBackground = true,
    this.scale = 1.0,
  });

  @override
  State<FavoriteButtonOverlay> createState() => _FavoriteButtonOverlayState();
}

class _FavoriteButtonOverlayState extends State<FavoriteButtonOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final AnimationController _ringController;
  late final AnimationController _particleController;

  late final Animation<double> _popScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  bool _prevFav = false;

  @override
  void initState() {
    super.initState();
    _prevFav = widget.isFavorite;

    // ❤️ ポップ
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
    ]).animate(_popController);

    // 🔘 リング
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _ringScale = Tween<double>(begin: 0.6, end: 1.6)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ringController);

    _ringOpacity = Tween<double>(begin: 0.45, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ringController);

    // ✨ 粒（NEW）
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant FavoriteButtonOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final turnedOn = (!_prevFav) && widget.isFavorite;
    _prevFav = widget.isFavorite;

    if (turnedOn) {
      HapticFeedback.lightImpact();
      _popController.forward(from: 0);
      _ringController.forward(from: 0);
      _particleController.forward(from: 0); // ← 追加
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color _iconColor(BuildContext context) {
    if (widget.isFavorite) {
      return Colors.redAccent;
    }

    if (widget.showBackground) {
      return Colors.white; // Middle（黒丸あり）
    }

    // ★ 背景なしの場合は「縁取り or 黒寄り」
    return Colors.black.withValues(alpha: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final double baseButtonSize = 56 * widget.scale;
    final double baseCircleSize = 44 * widget.scale;
    final double iconSize = 26 * widget.scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: SizedBox(
        width: baseButtonSize,
        height: baseButtonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✨ 粒（修正版）
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                if (_particleController.isDismissed) {
                  return const SizedBox.shrink(); // ← これが重要
                }
                return FavoriteBurstParticles(
                  animation: _particleController,
                  count: 5,
                  scale: widget.scale,
                );
              },
            ),

            // 🔘 リング
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                if (_ringController.isDismissed) {
                  return const SizedBox.shrink();
                }
                return Opacity(
                  opacity: _ringOpacity.value,
                  child: Transform.scale(
                    scale: _ringScale.value,
                    child: Container(
                      width: baseCircleSize,
                      height: baseCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 2 * widget.scale,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ❤️ ハート本体
            AnimatedBuilder(
              animation: _popController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _popScale.value,
                  child: child,
                );
              },
              child: Container(
                width: baseCircleSize,
                height: baseCircleSize,
                decoration: widget.showBackground
                    ? BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      )
                    : null, // ← ★ 背景なし
                child: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _iconColor(context),
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteBurstParticles extends StatelessWidget {
  final Animation<double> animation;
  final int count;
  final double scale;

  const FavoriteBurstParticles({
    super.key,
    required this.animation,
    this.scale = 1.0,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        return Stack(
          alignment: Alignment.center,
          children: List.generate(count, (i) {
            final angle = (2 * pi / count) * i;
            final distance = lerpDouble(0, 22 * scale, t)!;

            final dx = cos(angle) * distance;
            final dy = sin(angle) * distance;

            return Opacity(
              opacity: (1.0 - t).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
