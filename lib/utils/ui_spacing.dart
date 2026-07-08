import 'package:flutter/material.dart';

class UISpacing {
  static double fabBottomOffset(
    BuildContext context, {
    bool hasAd = false,
  }) {
    final media = MediaQuery.of(context);
    final isTablet = media.size.shortestSide >= 600;

    if (!hasAd) {
      return 15.0;
    }

    return isTablet ? 120.0 : 45.0;
  }

  static double bottomSpacer(
    BuildContext context, {
    bool hasFab = false,
    bool hasAd = false, // ★ デフォルトfalseに変更
    double? extraBuffer,
  }) {
    final media = MediaQuery.of(context);

    // SafeArea（ホームバー）
    final safeBottom = media.padding.bottom;

    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 600;

    // =============================
    // 🚫 重要：広告はMainで固定表示しているため加算しない
    // =============================
    double adHeight = 25;
    if (hasAd) {
      // 将来「画面内広告」にする場合のみ使用
      adHeight = isTablet ? 90.0 : 70.0;
    }

    // FABスペース（実測ベースに縮小）
    double fabSpace = 0;
    if (hasFab) {
      fabSpace = isTablet ? 72.0 : 64.0; // ← 80は過剰
    }

    final buffer = extraBuffer ?? 4.0; // ← 12→4に削減（隙間防止）

    return safeBottom + fabSpace + adHeight + buffer;
  }
}
