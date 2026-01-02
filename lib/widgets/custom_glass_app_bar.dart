// lib/widgets/custom_glass_app_bar.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

class CustomGlassAppBar extends StatelessWidget {
  final String title;
  final bool showRefreshButton;
  final bool isRefreshing;
  final VoidCallback? onRefreshPressed;

  final bool showInfoButton;
  final String? infoMessage;

  const CustomGlassAppBar({
    super.key,
    required this.title,
    this.showRefreshButton = false,
    this.isRefreshing = false,
    this.onRefreshPressed,
    this.showInfoButton = false,
    this.infoMessage,
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
                ),
              ),
            ),
          ),

          //
          // -------------------------------------------------------------
          // 🧩 コンテンツ（既存維持）
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
                  // 📺 タイトル＋Info＋更新（元ロジック維持）
                  //
                  SizedBox(
                    height: 28,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
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
                                    String resolveRegionLabel(Locale locale) {
                                      switch (locale.languageCode) {
                                        case 'ja':
                                          return "日本国内";
                                        case 'en':
                                          return "United States";
                                        // 追加予定
                                        // case 'fr': return "France";
                                        // case 'de': return "Germany";
                                        default:
                                          return "Worldwide";
                                      }
                                    }

                                    final l = AppLocalizations.of(context)!;
                                    final now = DateTime.now();
                                    final formatted =
                                        DateFormat.yMd(l.localeName)
                                            .add_Hm()
                                            .format(now);
                                    final region = resolveRegionLabel(
                                        Localizations.localeOf(context));
                                    final infoText = infoMessage ??
                                        l.infoTrendingUpdated(
                                            region, formatted);

                                    return _InfoButton(
                                      message: infoText,
                                      color: fgColor,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (showRefreshButton)
                          Positioned(
                            right: 0,
                            bottom: -13,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: isRefreshing ? null : onRefreshPressed,
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
                                  : Icon(Icons.refresh_rounded, color: fgColor),
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
}

//
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
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final box = context.findRenderObject() as RenderBox;
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

    Overlay.of(context).insert(_overlay!);
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      if (_overlay != null) {
        await _controller.reverse();
        _overlay?.remove();
        _overlay = null;
      }
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
