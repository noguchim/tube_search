// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/repeat_provider.dart';
import '../widgets/app_dialog.dart';

Future<void> showRepeatDialog(BuildContext context) async {
  final t = AppLocalizations.of(context)!;
  final provider = context.read<RepeatProvider>();

  var temp = provider.mode;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AppDialog(
        title: t.repeatDialogTitle,
        message: t.repeatDialogMessage,
        style: AppDialogStyle.info,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.repeatDialogCancel,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setMode(temp);
              Navigator.pop(context);
            },
            child: Text(t.repeatDialogSave),
          ),
        ],
        child: StatefulBuilder(
          builder: (context, set) {
            final isEnabled = temp != RepeatMode.off;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 連続再生 ON/OFF
                SwitchListTile(
                  title: Text("連続再生を有効にする"),
                  value: temp != RepeatMode.off,
                  onChanged: (on) {
                    set(() {
                      temp = on ? RepeatMode.ascending : RepeatMode.off;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // 🔹 再生方法（プルダウン）
                DropdownButtonFormField<RepeatMode>(
                  value: temp == RepeatMode.off ? RepeatMode.ascending : temp,
                  decoration: const InputDecoration(
                    labelText: "再生方法",
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RepeatMode.ascending,
                      child: Text("昇順で再生"),
                    ),
                    DropdownMenuItem(
                      value: RepeatMode.descending,
                      child: Text("降順で再生"),
                    ),
                    DropdownMenuItem(
                      value: RepeatMode.random,
                      child: Text("ランダム再生"),
                    ),
                  ],
                  onChanged: isEnabled ? (v) => set(() => temp = v!) : null,
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
