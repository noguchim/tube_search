import 'package:flutter/material.dart';

/// Rankバッジ（既存維持）
Widget rankBadge(BuildContext context, bool isDark, int rank) {
  final theme = Theme.of(context);

  Color baseColor;
  Color textColor;
  Border? border;

  if (rank == 1) {
    baseColor = theme.colorScheme.primary;
    textColor = Colors.white;
    border = null;
  } else if (rank == 2 || rank == 3) {
    baseColor = Colors.white;
    textColor = theme.colorScheme.primary;
    border = Border.all(color: theme.colorScheme.primary, width: 1.2);
  } else {
    baseColor = Colors.white;
    textColor = Colors.black87;
    border = Border.all(
      color: Colors.black26,
      width: 1.2,
    );
  }

  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(8),
      border: border,
    ),
    child: Center(
      child: Text(
        "$rank",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    ),
  );
}
