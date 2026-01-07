import 'package:flutter/material.dart';

enum ContinuousBadgeMode {
  off,
  ascending,
  descending,
  random,
}

class ContinuousPlayStatusBar extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onSettingsTap;
  final ContinuousBadgeMode mode; // ★ 追加

  const ContinuousPlayStatusBar({
    super.key,
    required this.enabled,
    required this.label,
    required this.onSettingsTap,
    required this.mode,
  });

  // 🎨 モード別カラー
  Color _badgeColor(ContinuousBadgeMode m) {
    switch (m) {
      case ContinuousBadgeMode.off:
        return const Color(0xFF9CA3AF); // gray
      case ContinuousBadgeMode.ascending:
        return const Color(0xFF3B82F6); // blue
      case ContinuousBadgeMode.descending:
        return const Color(0xFFF97316); // orange
      case ContinuousBadgeMode.random:
        return const Color(0xFFA855F7); // purple
    }
  }

  IconData _badgeIcon(ContinuousBadgeMode m) {
    switch (m) {
      case ContinuousBadgeMode.off:
        return Icons.block;
      case ContinuousBadgeMode.ascending:
        return Icons.trending_up;
      case ContinuousBadgeMode.descending:
        return Icons.trending_down;
      case ContinuousBadgeMode.random:
        return Icons.shuffle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final badgeBase = _badgeColor(mode);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? badgeBase.withValues(alpha: 0.45)
              : onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左のカラーライン
          Container(
            width: 4,
            height: 26,
            decoration: BoxDecoration(
              color: badgeBase,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 10),

          // ⭐ ここを「中央寄せブロック」に
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.repeat,
                  size: 20,
                  color: enabled ? badgeBase : onSurface.withValues(alpha: .55),
                ),

                const SizedBox(width: 8),

                Text(
                  "連続再生：",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),

                const SizedBox(width: 6),

                // ⭐ チップ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withValues(alpha: 0.92),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: enabled
                          ? badgeBase.withValues(alpha: 0.45)
                          : onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _badgeIcon(mode),
                        size: 14,
                        color: enabled
                            ? (theme.brightness == Brightness.light
                                ? badgeBase
                                : Colors.white)
                            : onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: enabled
                              ? (theme.brightness == Brightness.light
                                  ? badgeBase
                                  : Colors.white)
                              : onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 右の設定ボタン
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.settings),
            color: onSurface.withValues(alpha: .85),
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}
