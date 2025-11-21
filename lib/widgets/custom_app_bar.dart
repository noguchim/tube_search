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

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🪩 背景ブラー＋グラデーション
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xE6FFFFFF),
                      Color(0xCCE5E8EC),
                      Color(0x99D0D4D9),
                    ],
                  ),
                  color: const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                ),
              ),
            ),
          ),

          // コンテンツ
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
                  /// 🎬 ロゴ
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB5B9BE),
                            Color(0xFF646A70),
                            Color(0xFF3C4045),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow_rounded,
                              size: 19, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'TUBE+',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  /// 📺 タイトル＋Info＋更新ボタン
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
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                    height: 1.0,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ),

                              // ℹ️ Infoボタン（タップで吹き出し）
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
                              onPressed:
                              isRefreshing ? null : onRefreshPressed,
                              iconSize: 28,
                              icon: isRefreshing
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  color: Color(0xFF475569),
                                ),
                              )
                                  : const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF1E293B),
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

          // ✨ 下端ハイライト
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0x66FFFFFF),
                    Color(0x00FFFFFF),
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
    final renderBox = context.findRenderObject() as RenderBox;
    final Offset buttonGlobalPos = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    const double tooltipWidth = 260;
    const double verticalGap = 8;

    final screenWidth = MediaQuery.of(context).size.width;
    final double screenCenterX = screenWidth / 2; // ✅ 画面中央固定

    // 🎯 横位置（中央固定）
    final double tooltipLeft = (screenCenterX - tooltipWidth / 2)
        .clamp(8.0, screenWidth - tooltipWidth - 8.0);

    // 🎯 縦位置（infoボタンの下）
    final double tooltipTop = buttonGlobalPos.dy + buttonSize.height + verticalGap;

    _overlay = OverlayEntry(
      builder: (context) => Positioned(
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
                  // 🔺 上向き三角（吹き出しの上側に付ける）
                  Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      size: const Size(16, 8),
                      painter: _UpTrianglePainter(
                        color: Colors.grey.shade800.withValues(alpha: 0.95),
                      ),
                    ),
                  ),

                  // 吹き出し本体
                  Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.white,
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

    // ✅ rootOverlay: false → AppBar座標基準でズレなし
    Overlay.of(context).insert(_overlay!);
    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () async {
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
          margin: const EdgeInsets.only(left: 6.0),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
            _isPressed ? const Color(0xFFD9E2EC) : Colors.transparent,
            boxShadow: _isPressed
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ]
                : [],
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF475569),
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