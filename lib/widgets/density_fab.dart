import 'package:flutter/material.dart';

import '../utils/card_density_prefs.dart';

class DensityFab extends StatefulWidget {
  final CardDensity density;
  final VoidCallback onToggle;

  const DensityFab({
    super.key,
    required this.density,
    required this.onToggle,
  });

  @override
  State<DensityFab> createState() => _DensityFabState();
}

class _DensityFabState extends State<DensityFab> {
  bool _pressed = false;

  Color _densityColor(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        return const Color(0xFFEF4444); // 赤
      case CardDensity.middle:
        return const Color(0xFF10B981); // 緑
      case CardDensity.small:
        return const Color(0xFF3B82F6); // 青
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onToggle,
        onHighlightChanged: (value) {
          setState(() {
            _pressed = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.18 : 0.35),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _densityColor(widget.density),
              ),

              // =========================
              // ⭐ アイコン クロスフェード
              // =========================
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.9,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    _densityIcon(widget.density),
                    key: ValueKey(widget.density), // ← 超重要
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _densityIcon(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        return Icons.view_carousel_rounded;
      case CardDensity.middle:
        return Icons.view_agenda_rounded;
      case CardDensity.small:
        return Icons.view_list_rounded;
    }
  }
}
