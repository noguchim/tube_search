import 'package:flutter/material.dart';

/// Rankバッジ（既存維持）
Widget rankBadge(BuildContext context, int rank) {
  Color textColor;

  if (rank <= 3) {
    textColor = const Color(0xFF7CFF6B);
  } else {
    textColor = Colors.white;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '#$rank',
      style: TextStyle(
        color: textColor, // やや抑えた蛍光グリーン
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}
