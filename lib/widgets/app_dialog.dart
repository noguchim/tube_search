import 'package:flutter/material.dart';

enum AppDialogStyle {
  danger, // 赤
  info, // 青
}

enum AppDialogActionsAlignment {
  end, // 右寄せ（従来）
  center, // 中央寄せ（プレビュー等）
}

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;
  final AppDialogStyle style;
  final Widget? child;

  // ✅ 追加：右上×
  final bool showCloseButton;
  final VoidCallback? onClose;
  final AppDialogActionsAlignment actionsAlignment;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.style = AppDialogStyle.info,
    this.child,
    this.showCloseButton = false,
    this.onClose,
    this.actionsAlignment = AppDialogActionsAlignment.end,
  });

  Color _headerColor(BuildContext context) {
    switch (style) {
      case AppDialogStyle.danger:
        return const Color(0xFFEF4444);
      case AppDialogStyle.info:
        return Colors.blueAccent;
    }
  }

  Widget _buildActionsRow(BuildContext context) {
    final mainAxisAlignment = switch (actionsAlignment) {
      AppDialogActionsAlignment.end => MainAxisAlignment.end,
      AppDialogActionsAlignment.center => MainAxisAlignment.center,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: actions
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: a,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = _headerColor(context);

    // ✅ 背景色はテーマに従う（Dialogの背景）
    final dialogBgColor = theme.cardColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: headerColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          // ✅ ここが重要：高さが溢れる事故を回避
          maxHeight: 560,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 ヘッダー（Stackで×を重ねる）
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                if (showCloseButton)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      splashRadius: 20,
                      onPressed: onClose ?? () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),

            // 🔸 本文（message + child）
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // ← 追加
                  children: [
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity, // ← これが決定打
                          child: Text(
                            message,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    if (child != null) child!,
                  ],
                ),
              ),
            ),

            // 🔘 操作ボタン
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center, // ✅ 中央
            //     children: [
            //       ...actions.map((a) => Padding(
            //             padding: const EdgeInsets.symmetric(horizontal: 6),
            //             child: a,
            //           )),
            //     ],
            //   ),
            // ),

            _buildActionsRow(context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
