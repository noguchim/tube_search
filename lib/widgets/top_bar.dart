import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum TopBarMode {
  tabs, // パターンA：タブ表示
  back, // パターンB：戻る＋タイトル
}

class TopBarSpec {
  static const double barContentHeight = 50.0;
}

class TopBar extends StatelessWidget {
  final TopBarMode mode;

  // tabs 用
  final int selectedIndex;
  final double pageProgress;
  final bool isTapNavigating;
  final ValueChanged<int>? onTabSelected;

  // back 用
  final String? title;
  final VoidCallback? onBack;

  const TopBar({
    super.key,
    required this.mode,

    // tabs
    this.selectedIndex = 0,
    this.pageProgress = 0,
    this.isTapNavigating = false,
    this.onTabSelected,

    // back
    this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xAA000000) : const Color(0xFF282828);
    final borderColor = Colors.white.withValues(alpha: 0.10);
    final double safeTop = MediaQuery.of(context).padding.top;

    return Container(
      // 👇 StatusBar を含めた高さ
      height: safeTop + 50,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // 👇 中身だけを SafeArea 的に下げる
      child: Padding(
        padding: EdgeInsets.only(top: safeTop),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildTabs(context),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTab(
          context,
          index: 0,
          label: l.navPopular,
          activeColor: cs.primary,
        ),
        _buildTab(
          context,
          index: 1,
          label: l.navGenre,
          activeColor: cs.primary,
        ),
        _buildTab(
          context,
          index: 2,
          label: l.navFavorites,
          activeColor: cs.primary,
        ),
        _buildTab(
          context,
          index: 3,
          label: l.navSettings,
          activeColor: cs.primary,
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 🔥 タブ描画
  // ---------------------------------------------------------
  Widget _buildTab(
    BuildContext context, {
    required int index,
    required String label,
    required Color activeColor,
  }) {
    final bool isSelected = selectedIndex == index;

    // ★ タップ遷移中は補間無効
    final double t = isTapNavigating
        ? (isSelected ? 1.0 : 0.0)
        : (1.0 - (pageProgress - index).abs()).clamp(0.0, 1.0);

    // 🔥 縦位置はここで完全に統一
    const double tabTextCenterY = 6.0;

    final double topPadding =
        tabTextCenterY + (isSelected ? 0.0 : lerpDouble(0, 0, t)!);

    // ★ 次にアクティブになり得るか？
    final bool isCandidate = !isSelected && t > 0.0 && t < 1.0;

    const Color textColor = Color(0xFFB3B3B3);
    const double kTabHeight = 43;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onTabSelected?.call(index),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: SizedBox(
                height: kTabHeight, // ← ★同じ箱
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 非アクティブ
                    if (!isSelected)
                      Opacity(
                        opacity: isCandidate ? (1.0 - t) : 1.0,
                        child: Center(
                          // ← ★同一基準
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),

                    // アクティブ
                    if (isSelected || isCandidate)
                      Opacity(
                        opacity: isSelected ? 1.0 : t,
                        child: ChromeActiveTab(
                          title: label,
                          height: kTabHeight, // ← 同じ
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChromeActiveTab extends StatelessWidget {
  final String title;
  final double height;

  const ChromeActiveTab({
    super.key,
    required this.title,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height, // ← ★完全一致
      child: CustomPaint(
        painter: _ChromeActiveTabPainter(
          bgColor: theme.scaffoldBackgroundColor,
          isDark: isDark,
        ),
        child: Center(
          // ← ★ここだけで良い
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeActiveTabPainter extends CustomPainter {
  final Color bgColor;
  final bool isDark;

  _ChromeActiveTabPainter({
    required this.bgColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = bgColor;

    final borderPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double r = 9;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height)
      ..close();

    // 塗り（Body と同色）
    canvas.drawPath(path, bgPaint);

    // 上・左右のみ境界
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
