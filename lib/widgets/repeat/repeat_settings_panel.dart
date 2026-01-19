import 'package:flutter/material.dart';

import 'repeat_settings_content.dart';

Future<void> showRepeatSettingsPanel({
  required BuildContext context,
  required List<Map<String, dynamic>> videos,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        builder: (_, __) {
          final theme = Theme.of(context);

          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                // 背景
                Container(
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE67E22),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),

                Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RepeatSettingsContent(
                        videos: videos,
                        onClose: () => Navigator.pop(sheetContext),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
