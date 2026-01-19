import 'package:flutter/material.dart';
import 'package:tube_search/widgets/repeat/repeat_types.dart';

import '../app_dialog.dart';

class RepeatRangeResult {
  final List<Map<String, dynamic>> workingList;
  final int? startIndex;
  final int? endIndex;
  final int? startNo;
  final int? endNo;
  final SortMode sortMode;

  RepeatRangeResult({
    required this.workingList,
    required this.startIndex,
    required this.endIndex,
    required this.startNo,
    required this.endNo,
    required this.sortMode,
  });
}

Future<RepeatRangeResult?> showRepeatRangeDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> initialList,
  required SortMode initialSortMode,
  required int? startIndex,
  required int? endIndex,
  required int? startNo,
  required int? endNo,
  required Color accentColor,
}) async {
  return showDialog<RepeatRangeResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return _RepeatRangeDialog(
        initialList: initialList,
        initialSortMode: initialSortMode,
        startIndex: startIndex,
        endIndex: endIndex,
        startNo: startNo,
        endNo: endNo,
        accentColor: accentColor,
      );
    },
  );
}

class _RepeatRangeDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialList;
  final SortMode initialSortMode;
  final int? startIndex;
  final int? endIndex;
  final int? startNo;
  final int? endNo;
  final Color accentColor;

  const _RepeatRangeDialog({
    required this.initialList,
    required this.initialSortMode,
    required this.startIndex,
    required this.endIndex,
    required this.startNo,
    required this.endNo,
    required this.accentColor,
  });

  @override
  State<_RepeatRangeDialog> createState() => _RepeatRangeDialogState();
}

class _RepeatRangeDialogState extends State<_RepeatRangeDialog> {
  late List<Map<String, dynamic>> workingList;
  late SortMode sortMode;

  int? startIndex;
  int? endIndex;
  int? startNo;
  int? endNo;

  @override
  void initState() {
    super.initState();

    workingList =
        widget.initialList.map((e) => Map<String, dynamic>.from(e)).toList();

    sortMode = widget.initialSortMode;

    startIndex = widget.startIndex;
    endIndex = widget.endIndex;
    startNo = widget.startNo;
    endNo = widget.endNo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDialog(
      title: "再生範囲の指定",
      message: "",
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              // ✅ AppDialog内で使える最大高さまで埋める
              maxHeight: constraints.maxHeight,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingsCard(context),
                  const SizedBox(height: 10),

                  // ✅ ここから動画一覧も同一スクロールに入れる
                  _buildVideoListStatic(), // ← 新規
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "キャンセル",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            // 🔥 赤固定（danger）
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold, // ← ★ 強調
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: startIndex != null && endIndex != null
              ? () {
                  Navigator.pop(
                    context,
                    RepeatRangeResult(
                      workingList: workingList,
                      startIndex: startIndex,
                      endIndex: endIndex,
                      startNo: startNo,
                      endNo: endNo,
                      sortMode: sortMode,
                    ),
                  );
                }
              : null,
          child: const Text("確定"),
        ),
      ],
    );
  }

  Widget _sortIconGroup(ThemeData theme) {
    Widget btn({
      required IconData icon,
      required String tooltip,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final bg = selected
          ? widget.accentColor.withValues(alpha: 0.18)
          : theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF2F2F7);

      final border = selected
          ? widget.accentColor.withValues(alpha: 0.55)
          : theme.dividerColor.withValues(alpha: 0.6);

      final iconColor = selected
          ? widget.accentColor
          : theme.colorScheme.onSurface.withValues(alpha: 0.7);

      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            // height: 38,
            // width: 44,
            height: 34,
            width: 38,

            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          icon: Icons.arrow_upward,
          tooltip: "昇順",
          selected: sortMode == SortMode.asc,
          onTap: () => _changeSort(SortMode.asc),
        ),
        const SizedBox(width: 8),
        btn(
          icon: Icons.arrow_downward,
          tooltip: "降順",
          selected: sortMode == SortMode.desc,
          onTap: () => _changeSort(SortMode.desc),
        ),
        const SizedBox(width: 8),
        btn(
          icon: Icons.shuffle,
          tooltip: "ランダム",
          selected: sortMode == SortMode.random,
          onTap: () => _changeSort(SortMode.random),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortRow(context),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor,
          ),
          _buildRangeRow(context),
        ],
      ),
    );
  }

  Widget _buildSortRow(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              "並べ替え",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sortIconGroup(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              "再生範囲",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                _rangeBadge(
                  text: startNo == null ? "-" : "No.$startNo",
                  theme: theme,
                ),
                const SizedBox(width: 10),
                Text(
                  "〜",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 10),
                _rangeBadge(
                  text: endNo == null ? "-" : "No.$endNo",
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeBadge({
    required String text,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _changeSort(SortMode mode) {
    setState(() {
      sortMode = mode;

      if (mode == SortMode.asc) {
        workingList.sort(
            (a, b) => (a["_originalNo"] as int).compareTo(b["_originalNo"]));
      } else if (mode == SortMode.desc) {
        workingList.sort(
            (a, b) => (b["_originalNo"] as int).compareTo(a["_originalNo"]));
      } else {
        workingList.shuffle();
      }

      startIndex = endIndex = startNo = endNo = null;
    });
  }

  Widget _buildVideoListStatic() {
    final theme = Theme.of(context);
    final accent = widget.accentColor;

    return Column(
      children: List.generate(workingList.length, (index) {
        final video = workingList[index];

        final selected = startIndex != null &&
            endIndex != null &&
            index >= startIndex! &&
            index <= endIndex!;

        final no = video["_originalNo"] as int;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: selected
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (startIndex == null) {
                      startIndex = index;
                      startNo = no;
                    } else if (endIndex == null) {
                      if (index < startIndex!) return;
                      endIndex = index;
                      endNo = no;
                    } else {
                      startIndex = index;
                      startNo = no;
                      endIndex = endNo = null;
                    }
                  });
                },
                splashColor: accent.withValues(alpha: 0.12),
                highlightColor: accent.withValues(alpha: 0.06),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.95),
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          "$no",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          video["title"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Divider（最後の行には出さない）
            if (index != workingList.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
          ],
        );
      }),
    );
  }
}
