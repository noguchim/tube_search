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

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.style = AppDialogStyle.info,
  });

  Color _headerColor(BuildContext context) {
    switch (style) {
      case AppDialogStyle.danger:
        return const Color(0xFFEF4444); // アプリ赤
      case AppDialogStyle.info:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = _headerColor(context);

    return Dialog(
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

          // 🔸 本文
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔘 操作ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
