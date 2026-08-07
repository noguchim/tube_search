import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class LiveBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  const LiveBadge({
    super.key,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    this.backgroundColor = const Color(0xFFE53935),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        AppLocalizations.of(context)!.liveBadge,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
