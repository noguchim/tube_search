import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum TopBarMode {
  tabs, // パターンA：タブ表示
  back, // パターンB：戻る＋タイトル
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
    const bgColor = Color(0xFF111111);
    final borderColor = Colors.white.withValues(alpha: 0.10);

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: switch (mode) {
        TopBarMode.tabs => _buildTabs(context),
        TopBarMode.back => _buildBack(context),
      },
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

  Widget _buildBack(BuildContext context) {
    final textColor = Colors.white.withValues(alpha: 0.92);

    return SizedBox(
      height: 88, // ← TopBar 全体高さと合わせる
      child: Padding(
        padding: const EdgeInsets.only(
          top: 25,
          left: 8,
          right: 8,
        ),
        child: Center(
          child: SizedBox(
            height: 48, // ← 戻る・タイトル共通の縦基準
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // -------------------------
                // 戻るボタン
                // -------------------------
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // -------------------------
                // タイトル（縦中央完全一致）
                // -------------------------
                Expanded(
                  child: Center(
                    child: Text(
                      title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                // -------------------------
                // 右側ダミー
                // -------------------------
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
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

    // ★ 縦位置
    final double topPadding = isSelected ? 45 : lerpDouble(40, 45, t)!;

    // ★ 次にアクティブになり得るか？
    final bool isCandidate = !isSelected && t > 0.0 && t < 1.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // final Color textColor =
    // isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;
    final Color textColor = Colors.white.withValues(alpha: 0.92);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onTabSelected?.call(index),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // -------------------------
                  // 非アクティブ文字
                  // -------------------------
                  if (!isSelected)
                    Opacity(
                      opacity: isCandidate ? (1.0 - t) : 1.0,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),

                  // -------------------------
                  // ActiveTab
                  // -------------------------
                  if (isSelected || isCandidate)
                    Opacity(
                      opacity: isSelected ? 1.0 : t,
                      child: IgnorePointer(
                        ignoring: !isSelected,
                        child: ChromeActiveTab(
                          title: label,
                        ),
                      ),
                    ),
                ],
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

  const ChromeActiveTab({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // final Color bodyBg =
    // isDark ? const Color(0xFF121212) : const Color(0xFFF5F6F7);
    final Color bodyBg = theme.scaffoldBackgroundColor;

    final Color textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;

    final double elevation = isDark ? 0.0 : 0.6;

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: SizedBox(
        height: 42,
        child: CustomPaint(
          painter: _ChromeActiveTabPainter(
            bgColor: bodyBg,
            isDark: isDark,
          ),
          child: Padding(
            // ★ 縦を締める
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 72,
                maxWidth: 132,
              ),
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
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
