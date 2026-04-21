import 'package:flutter/material.dart';

class TopBarBack extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  // 🔥 ソート
  final ValueChanged<String>? onSortSelected;
  final String currentSort; // ← 追加（必須）
  final bool showSort;

  const TopBarBack({
    super.key,
    required this.title,
    required this.onBack,
    this.onSortSelected,
    this.currentSort = "score",
    this.showSort = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xAA000000) : const Color(0xFF282828);

    return Container(
      height: safeTop + 50,
      padding: EdgeInsets.fromLTRB(8, safeTop, 8, 0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ← 戻る
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // タイトル
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // 右側メニュー
            SizedBox(
              width: 48,
              child: (showSort && onSortSelected != null)
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: onSortSelected,
                      itemBuilder: (context) => [
                        _buildItem(context, "score", "スコア順"),
                        _buildItem(context, "views", "再生順"),
                        _buildItem(context, "date", "新着順"),
                      ],
                    )
                  : const SizedBox(), // ← ダミー
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // 🔥 チェック付きメニュー
  // =============================
  PopupMenuItem<String> _buildItem(
      BuildContext context, String value, String label) {
    final isSelected = currentSort == value;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: isSelected
                ? const Icon(Icons.check, size: 18)
                : const SizedBox(),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
