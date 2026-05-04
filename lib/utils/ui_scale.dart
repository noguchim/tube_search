import 'package:flutter/material.dart';

class UIScale {
  static const double _baseWidth = 375;

  static double _scale(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;

    // 🔥 guard①
    if (shortest <= 0 || shortest.isNaN || shortest.isInfinite) {
      return 1.0;
    }

    double raw = shortest / _baseWidth;

    // 🔥 guard②
    if (raw.isNaN || raw.isInfinite) {
      return 1.0;
    }

    raw = raw.clamp(0.9, 1.3);

    double scale = 1 + (raw - 1) * 0.5;

    // 🔥 guard③（最終防御）
    if (scale.isNaN || scale.isInfinite) {
      return 1.0;
    }

    return scale;
  }

  static double font(BuildContext context, double size) {
    return size * _scale(context);
  }

  static double icon(BuildContext context, double size) {
    return size * _scale(context);
  }

  static double height(BuildContext context, double size) {
    final scale = _scale(context);

    // スケール（弱め）
    final scaled = size * (1 + (scale - 1) * 0.3);

    // 🔥 視覚補正（重要）
    return scaled * 0.92;
  }

  static double space(BuildContext context, double size) {
    return size * _scale(context);
  }
}
