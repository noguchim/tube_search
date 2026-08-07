import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_back_button.dart';

class TopBarBack extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  // 🔥 ソート
  final ValueChanged<String>? onSortSelected;
  final String currentSort; // ← 追加（必須）
  final bool showSort;
  final VoidCallback? onContinueWatchTap;
  final bool continueWatchEnabled;
  final bool showContinueWatch;

  const TopBarBack({
    super.key,
    required this.title,
    required this.onBack,
    this.onSortSelected,
    this.currentSort = "score",
    this.showSort = true,
    this.onContinueWatchTap,
    this.continueWatchEnabled = false,
    this.showContinueWatch = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
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
            AppBackButton(onPressed: onBack, color: Colors.white),

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
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showContinueWatch)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        tooltip: l.continueWatchTooltip,
                        onPressed: continueWatchEnabled
                            ? onContinueWatchTap
                            : null,
                        icon: const Icon(Icons.playlist_play_rounded),
                        color: Colors.white,
                        disabledColor: Colors.white38,
                      ),
                    ),
                  if (showSort && onSortSelected != null)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.swap_vert, color: Colors.white),
                        tooltip: l.topBarSortTooltip,
                        onSelected: onSortSelected,
                        itemBuilder: (context) => [
                          _buildItem(context, "score", l.sortByScore),
                          _buildItem(context, "views", l.sortByViews),
                          _buildItem(context, "date", l.sortByNewest),
                        ],
                      ),
                    ),
                ],
              ),
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
    BuildContext context,
    String value,
    String label,
  ) {
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
