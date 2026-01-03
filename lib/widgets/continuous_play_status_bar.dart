import 'package:flutter/material.dart';

class ContinuousPlayStatusBar extends StatelessWidget {
  final bool enabled;
  final String mode; // "asc" | "desc" | "random"
  final VoidCallback onSettingsTap;

  const ContinuousPlayStatusBar({
    super.key,
    required this.enabled,
    required this.mode,
    required this.onSettingsTap,
  });

  String _label() {
    if (!enabled) return "OFF";

    switch (mode) {
      case "asc":
        return "ON（昇順）";
      case "desc":
        return "ON（降順）";
      case "random":
        return "ON（ランダム）";
      default:
        return "ON";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            "連続再生：${_label()}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings),
            color: theme.colorScheme.onSurface,
            onPressed: onSettingsTap,
          )
        ],
      ),
    );
  }
}
