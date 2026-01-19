import 'package:flutter/material.dart';
import 'package:tube_search/widgets/repeat/repeat_types.dart';

import '../app_dialog.dart';

class RepeatPreviewInfo {
  final String name;
  final String sortLabel;
  final String rangeLabel;

  final String? firstVideoId;
  final String firstVideoTitle;

  const RepeatPreviewInfo({
    required this.name,
    required this.sortLabel,
    required this.rangeLabel,
    required this.firstVideoId,
    required this.firstVideoTitle,
  });
}

Future<PreviewAction?> showRepeatPreviewDialog({
  required BuildContext context,
  required RepeatPreviewInfo info,
  required Color accentColor,
}) async {
  return showDialog<PreviewAction>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return AppDialog(
        title: "プレビュー",
        message: "",
        showCloseButton: true,
        actionsAlignment: AppDialogActionsAlignment.center,
        onClose: () => Navigator.pop(context, PreviewAction.cancel),
        child: _PreviewBody(
          info: info,
          accentColor: accentColor,
        ),
        actions: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 280, // ✅ これがセンターに固定される
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, PreviewAction.saveOnly),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "保存",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, PreviewAction.saveAndPlay),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "保存＆再生",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PreviewBody extends StatelessWidget {
  final RepeatPreviewInfo info;
  final Color accentColor;

  const _PreviewBody({
    required this.info,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final thumbUrl = (info.firstVideoId == null)
        ? null
        : "https://i.ytimg.com/vi/${info.firstVideoId}/hqdefault.jpg";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📛 リスト名：${info.name}"),
                Text("🔁 再生方法：${info.sortLabel}"),
                Text("🎯 再生範囲：${info.rangeLabel}"),
                const SizedBox(height: 12),
                const Text(
                  "▶ 最初の動画",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // サムネ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 104,
                        height: 58,
                        child: thumbUrl == null
                            ? const ColoredBox(
                                color: Color(0xFFE5E7EB),
                              )
                            : Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFFE5E7EB)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // タイトル
                    Expanded(
                      child: Text(
                        info.firstVideoTitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ✅ スクロール出ても表示崩れないよう補助
        Text(
          "※保存後に履歴からいつでも再生できます",
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
