import 'package:flutter/material.dart';

enum AppDialogStyle {
  danger, // 赤
  info, // 青
}

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;
  final AppDialogStyle style;
  final Widget? child;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.style = AppDialogStyle.info,
    this.child,
  });

  Color _headerColor(BuildContext context) {
    switch (style) {
      case AppDialogStyle.danger:
        return const Color(0xFFEF4444);
      case AppDialogStyle.info:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = _headerColor(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: headerColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 🔸 本文（message + child）
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (child != null) child!,
              ],
            ),
          ),

          // 🔘 操作ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 12),
              ...actions.map((a) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: a,
                  )),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
