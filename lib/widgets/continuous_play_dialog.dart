import 'package:flutter/material.dart';

class ContinuousPlayDialog extends StatefulWidget {
  const ContinuousPlayDialog({super.key});

  @override
  State<ContinuousPlayDialog> createState() => _ContinuousPlayDialogState();
}

class _ContinuousPlayDialogState extends State<ContinuousPlayDialog> {
  bool _enabled = false;
  String _mode = "asc";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- タイトル -----
            Text(
              "連続再生設定",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // ----- ON/OFF -----
            SwitchListTile(
              value: _enabled,
              title: const Text("連続再生を有効にする"),
              onChanged: (v) => setState(() => _enabled = v),
            ),

            const Divider(),

            // ----- モード選択 -----
            const SizedBox(height: 4),
            const Text("再生方法"),

            RadioListTile<String>(
              value: "asc",
              groupValue: _mode,
              title: const Text("昇順（上から順番）"),
              onChanged: _enabled
                  ? (String? v) => setState(() => _mode = v ?? "asc")
                  : null,
            ),

            RadioListTile<String>(
              value: "desc",
              groupValue: _mode,
              title: const Text("降順（下から順番）"),
              onChanged: _enabled
                  ? (String? v) => setState(() => _mode = v ?? "desc")
                  : null,
            ),

            RadioListTile<String>(
              value: "random",
              groupValue: _mode,
              title: const Text("ランダム"),
              onChanged: _enabled
                  ? (String? v) => setState(() => _mode = v ?? "random")
                  : null,
            ),

            const SizedBox(height: 6),

            // ----- ボタン -----
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("閉じる"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
