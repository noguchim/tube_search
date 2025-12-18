import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_glass_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _prefSkipDeleteConfirm = "skip_delete_confirm";

  bool _skipDeleteConfirm = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefSkipDeleteConfirm) ?? false;

    setState(() {
      _skipDeleteConfirm = value;
      _loading = false;
    });
  }

  Future<void> _updateSkipConfirm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSkipDeleteConfirm, value);

    setState(() {
      _skipDeleteConfirm = value;
    });
  }

  // -------------------------------------------------------------------
  // 🔥 現在の ThemeMode を文字に変換（ListTile 表示用）
  // -------------------------------------------------------------------
  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return "ダーク";
      case ThemeMode.light:
        return "ライト";
      default:
        return "デバイス設定";
    }
  }

  // -------------------------------------------------------------------
  // 🔥 YouTube 風テーマ選択ダイアログ（BottomSheet）
  // -------------------------------------------------------------------
  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // --- デバイス設定 ---
            _buildOption(
              context,
              label: "デバイスのモードを使用",
              selected: provider.themeMode == ThemeMode.system,
              onTap: () {
                provider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),

            // --- ライト ---
            _buildOption(
              context,
              label: "ライトモード",
              selected: provider.themeMode == ThemeMode.light,
              onTap: () {
                provider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),

            // --- ダーク ---
            _buildOption(
              context,
              label: "ダークモード",
              selected: provider.themeMode == ThemeMode.dark,
              onTap: () {
                provider.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // 🔥 ダイアログの 1 行パーツ（✓ アイコン付き）
  // -------------------------------------------------------------------
  Widget _buildOption(
      BuildContext context, {
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  // -------------------------------------------------------------------
  // 🔥 お気に入り削除設定の選択ダイアログ
  // -------------------------------------------------------------------
  void _showDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // --- する ---
            _buildDeleteOption(
              context,
              label: "する",
              selected: !_skipDeleteConfirm,
              onTap: () {
                _updateSkipConfirm(false); // false → 「する（確認する）」
                Navigator.pop(context);
              },
            ),

            // --- しない ---
            _buildDeleteOption(
              context,
              label: "しない",
              selected: _skipDeleteConfirm,
              onTap: () {
                _updateSkipConfirm(true); // true → 「しない（確認しない）」
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _showRemoveAdsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "広告表示について",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "現在：広告を表示しています\n\n広告を非表示にすると、画面下のバナーが消え、より快適に利用できます。",
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 購入ボタン ---
            ListTile(
              title: const Text(
                "広告を非表示にする（¥300）",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: onSurface),
              onTap: () {
                Navigator.pop(context);
                // TODO: 課金処理へ（次フェーズで実装）
                debugPrint("Start purchase flow");
              },
            ),

            const SizedBox(height: 8),

            // --- キャンセル ---
            ListTile(
              title: const Center(
                child: Text(
                  "キャンセル",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // 🔥 ダイアログ1行パーツ（✓ 表示）
  // -------------------------------------------------------------------
  Widget _buildDeleteOption(
      BuildContext context, {
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardTheme = theme.cardTheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 🪩 ガラス AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 70,
            flexibleSpace: const CustomGlassAppBar(title: '設定'),
          ),

          // 本体
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),

                // ------------------------------------
                // ⭐ テーマ設定セクション（YouTube 風 ListTile）
                // ------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "テーマ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Material(
                  color: cardTheme.color,
                  elevation: cardTheme.elevation ?? 0,
                  shape: cardTheme.shape,
                  child: ListTile(
                    leading: Icon(Icons.dark_mode, color: onSurface),
                    title: Text(
                      "デザイン: ${_themeLabel(themeProvider.themeMode)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    trailing:
                    Icon(Icons.chevron_right_rounded, color: onSurface),
                    onTap: () => _showThemeDialog(context, themeProvider),
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------
                // ⭐ お気に入りセクション
                // ------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "お気に入り",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Material(
                  color: cardTheme.color,
                  elevation: cardTheme.elevation ?? 0,
                  shape: cardTheme.shape,
                  child: ListTile(
                    leading: Icon(Icons.favorite_rounded, color: onSurface),
                    title: Text(
                      "削除時に確認",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),

                    // --- 現在の設定表示 ---
                    subtitle: Text(
                      _skipDeleteConfirm ? "しない" : "する",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    trailing: Icon(Icons.chevron_right_rounded, color: onSurface),

                    // --- ダイアログ表示 ---
                    onTap: () => _showDeleteConfirmDialog(context),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------
                // ⭐ 広告セクション
                // ------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "広告",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Material(
                  color: cardTheme.color,
                  elevation: cardTheme.elevation ?? 0,
                  shape: cardTheme.shape,
                  child: ListTile(
                    leading: Icon(Icons.ads_click, color: onSurface),
                    title: const Text(
                      "広告表示",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // 🔥 ここはデフォルトでは「表示中」
                    // 課金後は "非表示（購入済み）" に書き換える予定
                    subtitle: const Text(
                      "表示中",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),

                    trailing: Icon(Icons.chevron_right_rounded, color: onSurface),

                    onTap: () => _showRemoveAdsDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
