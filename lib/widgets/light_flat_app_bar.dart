import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../utils/app_logger.dart';
import '../utils/card_density_prefs.dart';

enum AppBarTitleAlign {
  center,
  left,
}

class LightFlatAppBar extends StatelessWidget {
  final String title;
  final bool showRefreshButton;
  final bool isRefreshing;
  final VoidCallback? onRefreshPressed;
  final bool showInfoButton;
  final DateTime? fetchedAt;
  final bool showDensityButton;
  final CardDensity density;
  final VoidCallback? onToggleDensity;
  final bool reserveLeadingSpace;
  final AppBarTitleAlign titleAlign;

  const LightFlatAppBar({
    super.key,
    required this.title,
    this.showRefreshButton = false,
    this.isRefreshing = false,
    this.onRefreshPressed,
    this.showInfoButton = false,
    this.fetchedAt,
    this.showDensityButton = false,
    this.density = CardDensity.big,
    this.onToggleDensity,
    this.reserveLeadingSpace = false,
    this.titleAlign = AppBarTitleAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final bool isDark = theme.brightness == Brightness.dark;

    //
    // -------------------------------------------------------------
    // 🎨 BottomNav と同じ背景色（完全一致）
    // -------------------------------------------------------------
    //
    final List<Color> bgGradient = isDark
        ? [
            const Color(0xCC111111),
            const Color(0xB31A1A1A),
            const Color(0x991A1A1A),
          ]
        : [
            const Color(0xE6FFFFFF),
            const Color(0xCCE5E8EC),
            const Color(0x99D0D4D9),
          ];

    final Color bgColor = isDark
        ? const Color(0xFF111111).withValues(alpha: 0.85)
        : const Color(0xFFF9FAFB).withValues(alpha: 0.85);

    //
    // -------------------------------------------------------------
    // 🎨 ライト → 黒系、ダーク → 白系
    // -------------------------------------------------------------
    //
    final Color fgColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final double leftReserve = reserveLeadingSpace ? 44 : 0;

    final double rightReserve =
        (showRefreshButton ? 40 : 0) + (showDensityButton ? 36 : 0) + 6;

    Widget buildTitleRow(BoxConstraints constraints) {
      final maxTitleWidth = (constraints.maxWidth - leftReserve - rightReserve)
          .clamp(120.0, constraints.maxWidth);

      final row = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxTitleWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: titleAlign == AppBarTitleAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                title,
                textAlign: titleAlign == AppBarTitleAlign.center
                    ? TextAlign.center
                    : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                  height: 1.0,
                  letterSpacing: 0.25,
                ),
              ),
            ),
            if (showInfoButton)
              Builder(
                builder: (_) {
                  final l = AppLocalizations.of(context)!;
                  final dt = fetchedAt;
                  final formatted = (dt == null)
                      ? "--"
                      : DateFormat.yMd(l.localeName).add_Hm().format(dt);

                  // ✅ RegionProvider の設定値を参照
                  final regionCode = context.read<RegionProvider>().regionCode;

                  // ✅ 地域ラベルをregionCodeで決定（ローカライズ対応）
                  String resolveRegionLabel(String code) {
                    switch (code) {
                      case "JP":
                        return l.regionJapan; // ← 追加するローカライズキー
                      case "US":
                        return l.regionUnitedStates;
                      case "GB":
                        return l.regionUnitedKingdom;
                      case "DE":
                        return l.regionGermany;
                      case "FR":
                        return l.regionFrance;
                      case "IN":
                        return l.regionIndia;
                      default:
                        return code;
                    }
                  }

                  final regionLabel = resolveRegionLabel(regionCode);
                  final infoText =
                      l.infoTrendingUpdated(regionLabel, formatted);
                  logger.i("info text = $infoText");

                  return _InfoButton(
                    message: infoText,
                    color: fgColor,
                  );
                },
              ),
          ],
        ),
      );

      if (titleAlign == AppBarTitleAlign.center) {
        // ✅ Popularなど：センター
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: Center(child: row),
          ),
        );
      }

      // ✅ Genreなど：左寄せ（戻る分のpaddingを確保）
      return Align(
        alignment: Alignment.bottomLeft,
        child: Transform.translate(
          offset: const Offset(0, 2),
          child: Padding(
            padding: EdgeInsets.only(left: leftReserve),
            child: row,
          ),
        ),
      );
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🪩 ガラス背景（ブラー＋グラデ）
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: bgGradient,
                  ),
                  color: bgColor,

                  // ✅ 境界
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          //
          // -------------------------------------------------------------
          // 🧩 コンテンツ
          // -------------------------------------------------------------
          //
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: topInset > 0 ? 1 : 0,
                left: 12,
                right: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //
                  // 🎬 ロゴ段（少し低め）
                  //
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            size: 16, color: fgColor.withValues(alpha: 0.90)),
                        const SizedBox(width: 4),
                        Text(
                          'TUBE+',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
                            color: fgColor.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  //
                  // 📺 タイトル＋Info＋更新＋（左：密度ボタン）
                  //
                  SizedBox(
                    height: 28,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // ✅ 中央：タイトル + Info（既存ベース維持しつつ “被り回避” を maxWidth で行う）
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                buildTitleRow(constraints),
                          ),
                        ),

                        // ✅ 右：切替ボタン → 更新ボタン（並び順固定）
                        Positioned(
                          right: 0,
                          bottom: -13,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDensityButton)
                                Transform.translate(
                                  offset: const Offset(10, 0), // ✅ 更新側に寄せる
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: onToggleDensity,
                                    iconSize: 26,
                                    tooltip: _densityTooltip(density),
                                    icon: Icon(
                                      _densityIcon(density),
                                      color: fgColor,
                                    ),
                                  ),
                                ),
                              if (showRefreshButton)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed:
                                      isRefreshing ? null : onRefreshPressed,
                                  iconSize: 28,
                                  icon: isRefreshing
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.8,
                                            color: fgColor,
                                          ),
                                        )
                                      : Icon(Icons.refresh_rounded,
                                          color: fgColor),
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
        ],
      ),
    );
  }

  IconData _densityIcon(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        // return Icons.crop_portrait_rounded; // Bigカード
        return Icons.view_carousel_rounded; // Bigカード
      case CardDensity.middle:
        return Icons.view_agenda_rounded; // Middle（縦カード）
      case CardDensity.small:
        return Icons.view_list_rounded; // Small（横並びCompact）
    }
  }

  String _densityTooltip(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        return "大カード表示";
      case CardDensity.middle:
        return "中カード表示";
      case CardDensity.small:
        return "小カード表示";
    }
  }
}

// =============================================================
// 🔥 Infoボタン（色も fgColor に合わせて変更可能に）
// =============================================================
class _InfoButton extends StatefulWidget {
  final String message;
  final Color color;

  const _InfoButton({
    required this.message,
    required this.color,
  });

  @override
  State<_InfoButton> createState() => _InfoButtonState();
}

class _InfoButtonState extends State<_InfoButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlay;
  bool _isPressed = false;

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  Timer? _autoCloseTimer; // ✅ 追加

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    // ✅ 重要：破棄される時に overlay を必ず remove
    _autoCloseTimer?.cancel();
    _removeOverlayImmediately();

    _controller.dispose();
    super.dispose();
  }

  void _removeOverlayImmediately() {
    try {
      _overlay?.remove();
    } catch (_) {}
    _overlay = null;
  }

  Future<void> _closeOverlay() async {
    _autoCloseTimer?.cancel();
    if (_overlay == null) return;

    try {
      await _controller.reverse();
    } catch (_) {}

    _removeOverlayImmediately();
  }

  void _showTooltip(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 既に出てるなら先に閉じる（更新/連打対策）
    await _closeOverlay();

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    const double width = 260;
    const double gap = 8;

    final screenWidth = MediaQuery.of(context).size.width;
    final double left =
        (screenWidth / 2 - width / 2).clamp(8, screenWidth - width - 8);

    final double top = pos.dy + size.height + gap;

    final Color tooltipBg = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.grey.shade800.withValues(alpha: 0.95);

    final Color tooltipTextColor = isDark ? Colors.black87 : Colors.white;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: top,
        left: left,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  CustomPaint(
                    size: const Size(16, 8),
                    painter: _UpTrianglePainter(color: tooltipBg),
                  ),
                  Container(
                    width: width,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tooltipBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: tooltipTextColor,
                        fontSize: 13,
                        height: 1.4,
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

    final overlay = Overlay.of(context);
    overlay.insert(_overlay!);

    await _controller.forward();

    // ✅ 自動クローズも Timer で管理（更新でdisposeされてもcancelできる）
    _autoCloseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _closeOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _showTooltip(context);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(2),
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? Colors.black12 : Colors.transparent,
        ),
        child: Icon(Icons.info_outline_rounded, color: widget.color, size: 20),
      ),
    );
  }
}

class _UpTrianglePainter extends CustomPainter {
  final Color color;

  const _UpTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_UpTrianglePainter old) => old.color != color;
}
