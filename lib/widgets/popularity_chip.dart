import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color popularityColor(BuildContext context, int popularity) {
  if (popularity >= 1000) {
    return const Color(0xFFEF4444);
  }

  if (popularity >= 500) {
    return const Color(0xFF10B981);
  }

  return const Color(0xFF3B82F6);
}

class PopularityChip extends StatelessWidget {
  final int popularity;

  /// optional size parameters
  final double fontSize;
  final double iconSize;
  final double height;

  const PopularityChip({
    super.key,
    required this.popularity,
    this.fontSize = 13,
    this.iconSize = 16,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = popularityColor(context, popularity);
    final format = NumberFormat("#,###");

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.45,
        // vertical: fontSize * 0.12,
      ),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.north_east_rounded,
            size: iconSize,
            color: Colors.white,
          ),
          SizedBox(width: fontSize * 0.15),
          Text(
            format.format(popularity),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
