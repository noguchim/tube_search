import 'package:flutter/material.dart';

import 'repeat_types.dart';

class RepeatHeaderSwitch extends StatelessWidget {
  final RepeatTab currentTab;
  final Color color;
  final ValueChanged<RepeatTab> onChanged;

  // ✅追加：編集中かどうか（editingId!=null）
  final bool isEditing;

  const RepeatHeaderSwitch({
    super.key,
    required this.currentTab,
    required this.color,
    required this.onChanged,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _seg("新規設定", RepeatTab.newSetting),
          _seg("設定履歴", RepeatTab.history),
        ],
      ),
    );
  }

  Widget _seg(String label, RepeatTab tab) {
    final selected = currentTab == tab;

    final showEditingBadge =
        isEditing && tab == RepeatTab.newSetting; // ✅ 新規設定にだけ表示

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.white,
                ),
              ),
              if (showEditingBadge) ...[
                const SizedBox(width: 6),
                _editingBadge(selected: selected),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _editingBadge({required bool selected}) {
    // 選択中は背景が白 → badgeは少し濃いめに
    final bg =
        selected ? color.withOpacity(0.12) : Colors.white.withOpacity(0.18);
    final border =
        selected ? color.withOpacity(0.45) : Colors.white.withOpacity(0.35);
    final fg = selected ? color : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        "編集中",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
