// lib/widgets/custom_app_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';

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
    final topInset = MediaQuery.of(context).padding.top;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // -----------------------------------------------------
    // 🎨 Light / Dark 用の背景色グラデーション
    // -----------------------------------------------------
    final List<Color> bgGradient = isDark
        ? [
            const Color(0xCC1A1A1A),
            const Color(0xB31A1A1A),
            const Color(0x991A1A1A),
          ]
        : [
            const Color(0xE6FFFFFF),
            const Color(0xCCE5E8EC),
            const Color(0x99D0D4D9),
          ];

    final Color bgColor = isDark
        ? const Color(0xFF1A1A1A).withOpacity(0.85)
        : const Color(0xFFF9FAFB).withOpacity(0.75);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🪩 背景ブラー（Glass）
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

          // -----------------------------------------------------
          // 🧩 コンテンツ
          // -----------------------------------------------------
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
                  // -----------------------------------------------------
                  // 🎬 ロゴ（単色：Light=黒、Dark=白）
                  // -----------------------------------------------------
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 19,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'TUBE+',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  // -----------------------------------------------------
                  // 📺 タイトル＋Info＋更新ボタン
                  // -----------------------------------------------------
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
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                    height: 1.0,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ),

                              // ℹ️ Infoボタン
                              if (showInfoButton)
                                _InfoButton(
                                  message: infoMessage ??
                                      'YouTube急上昇ランキング（日本国内・トレンド反映）',
                                ),
                            ],
                          ),
                        ),

                        // 🔄 更新ボタン
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
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF475569),
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                              tooltip: '最新の情報を取得',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✨ 下端ハイライト（Light/Dark共通）
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white24,
                          Colors.white10,
                          Colors.transparent,
                        ]
                      : [
                          Colors.white,
                          Colors.white60,
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ===========================================================
// 🔥 Infoボタン（Tooltip） 〜 Light / Dark 完全対応版
// ===========================================================
//
class _InfoButton extends StatefulWidget {
  final String message;

  const _InfoButton({required this.message});

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

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final renderBox = context.findRenderObject() as RenderBox;
    final Offset buttonGlobalPos = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    const double tooltipWidth = 260;
    const double verticalGap = 8;

    final screenWidth = MediaQuery.of(context).size.width;
    final double screenCenterX = screenWidth / 2;

    final double tooltipLeft = (screenCenterX - tooltipWidth / 2)
        .clamp(8, screenWidth - tooltipWidth - 8)
        .toDouble();

    final double tooltipTop =
        buttonGlobalPos.dy + buttonSize.height + verticalGap;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: tooltipTop,
        left: tooltipLeft,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔺 三角
                  Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      size: const Size(16, 8),
                      painter: _UpTrianglePainter(
                        color: isDark
                            ? Colors.white.withOpacity(0.95)
                            : Colors.grey.shade800.withOpacity(0.95),
                      ),
                    ),
                  ),

                  // 吹き出し本体
                  Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.95)
                          : Colors.grey.shade800.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: isDark ? Colors.black87 : Colors.white,
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
      if (mounted && _overlay != null) {
        await _controller.reverse();
        _hideTooltip();
      }
    });
  }

  void _hideTooltip() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _showTooltip(context);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed
                ? (isDark ? Colors.white12 : Colors.black12)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.info_outline_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            size: 20,
          ),
        ),
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
  bool shouldRepaint(_UpTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
