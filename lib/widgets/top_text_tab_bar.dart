import 'package:flutter/material.dart';

class TopTextTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  const TopTextTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor =
        isDark ? Colors.white.withOpacity(0.95) : Colors.black87;
    final inactiveColor =
        isDark ? Colors.white.withOpacity(0.55) : Colors.black54;

    return SafeArea(
      bottom: false,
      child: Padding(
        // 👇 ここで「もっと上」に寄せる
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          height: 36, // ← 薄く、AppBar感を消す
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(labels.length, (index) {
              final isActive = index == currentIndex;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(index),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.4,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
