import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'repeat_types.dart';

class RepeatNewTab extends StatelessWidget {
  final TextEditingController listNameController;
  final ValueChanged<String> onListNameChanged;

  final bool useFullRange;
  final SortMode sortMode;

  final int? startNo;
  final int? endNo;

  final bool isLimitReached;
  final String? editingId;
  final Color panelColor;

  /// ✅「全て」へ切替
  final VoidCallback onTapAll;

  /// ✅「範囲指定」→ダイアログ表示
  final Future<void> Function() onTapRange;

  /// ✅ 保存可否
  final bool Function() canSave;
  final VoidCallback onClosePanel;
  final Future<void> Function() onPressPreview;

  const RepeatNewTab({
    super.key,
    required this.listNameController,
    required this.onListNameChanged,
    required this.useFullRange,
    required this.sortMode,
    required this.startNo,
    required this.endNo,
    required this.isLimitReached,
    required this.editingId,
    required this.panelColor,
    required this.onTapAll,
    required this.onTapRange,
    required this.canSave,
    required this.onClosePanel,
    required this.onPressPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ 上部パディング領域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildListNameSection(context),
              const SizedBox(height: 12),
              _buildRangeSection(context),
            ],
          ),
        ),

        const Spacer(),

        // ✅ bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onClosePanel,
                  style: FilledButton.styleFrom(
                    // ✅ 白塗り（ライト：白 / ダーク：既存Glass）
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,

                    // ✅ 既存踏襲：角丸（プレビューボタンに合わせる）
                    shape: const StadiumBorder(),

                    // ✅ 既存踏襲：高さ（FilledButtonの既定を維持）
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text("設定終了"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: panelColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),

                    // ✅ 既存踏襲
                    shape: const StadiumBorder(),
                  ),
                  onPressed: canSave() ? onPressPreview : null,
                  child: const Text("プレビュー"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────
  // リスト名（iOS風）
  // ────────────────────────────────
  Widget _buildListNameSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelColor = theme.extension<AppColors>()!.label;

    // ✅ 入力有無
    final hasName = listNameController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // ✅ 見出し（＋右にチェック）
        Row(
          children: [
            Text(
              "リスト名",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 8),

            // ✅ ステータス表示
            _statusBadge(
              context: context,
              isOk: hasName,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ✅ 入力欄
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),

            // ✅ 必須の状態が分かりやすいように（未入力時だけ薄い赤枠）
            border: Border.all(
              color: hasName
                  ? Colors.transparent
                  : const Color(0xFFEF4444).withValues(alpha: 0.40),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: listNameController,
            onChanged: onListNameChanged,

            // ✅ 入力文字を太く
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600, // ← ★ ここで太く
              color: theme.colorScheme.onSurface,
            ),

            decoration: InputDecoration(
              hintText: "連続再生リスト名を入力",
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500, // hintもちょい太めで整える
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────
  // 再生範囲（iOS風チェック＋範囲指定はダイアログ）
  // ────────────────────────────────
  Widget _buildRangeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        // ✅ 見出し + OK/NGチェック
        _buildRangeTitle(context),

        const SizedBox(height: 8),

        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _checkRow(
                context: context,
                label: "全て",
                selected: useFullRange,
                onTap: onTapAll,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                rowHeight: 46,
                horizontalPadding: 16,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor,
              ),
              _checkRow(
                context: context,
                label: "範囲指定",
                selected: !useFullRange,
                onTap: () async => await onTapRange(),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                rowHeight: 46,
                horizontalPadding: 16,
              ),
            ],
          ),
        ),

        // ✅ 範囲の状態表示（おすすめ）
        _buildRangeSummary(context),
      ],
    );
  }

  Widget _buildRangeTitle(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.extension<AppColors>()!.label;

    final isOk = useFullRange || (startNo != null && endNo != null);

    return Row(
      children: [
        Text(
          "再生範囲",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: labelColor,
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(
          context: context,
          isOk: isOk,
        ),
      ],
    );
  }

  Widget _buildRangeSummary(BuildContext context) {
    final theme = Theme.of(context);

    if (useFullRange) return const SizedBox.shrink();

    final ok = startNo != null && endNo != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        ok ? "開始：No.$startNo 〜 終了：No.$endNo" : "範囲が未設定です（範囲指定を確定してください）",
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: ok
              ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
              : Colors.red.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _checkRow({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? accentColor, // required を外す

    double rowHeight = 44,
    double horizontalPadding = 14,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: rowHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check,
                  size: 20,
                  color: accentColor ?? panelColor, // ✅ ここでpanelColor使用
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required BuildContext context,
    required bool isOk,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final checkColor = isOk ? Colors.green : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: checkColor.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: checkColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: checkColor),
          const SizedBox(width: 4),
          Text(
            isOk ? "OK" : "未確定",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: checkColor,
            ),
          ),
        ],
      ),
    );
  }
}
