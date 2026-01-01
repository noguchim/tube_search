import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/policy_webview_screen.dart';
import 'package:tube_search/screens/shop_screen.dart';

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
  // 🔥 現在の ThemeMode を文字に変換
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
  // 🔥 テーマ変更ダイアログ
  // -------------------------------------------------------------------
  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    final theme = Theme.of(context);

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
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              label: "デバイスのモードを使用",
              selected: provider.themeMode == ThemeMode.system,
              onTap: () {
                provider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              label: "ライトモード",
              selected: provider.themeMode == ThemeMode.light,
              onTap: () {
                provider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
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
      trailing:
          selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }

  // -------------------------------------------------------------------
  // 🔥 お気に入り削除設定ダイアログ
  // -------------------------------------------------------------------
  void _showDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);

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
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            _buildDeleteOption(
              context,
              label: "する",
              selected: !_skipDeleteConfirm,
              onTap: () {
                _updateSkipConfirm(false);
                Navigator.pop(context);
              },
            ),
            _buildDeleteOption(
              context,
              label: "しない",
              selected: _skipDeleteConfirm,
              onTap: () {
                _updateSkipConfirm(true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

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
      trailing:
          selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }

  void _showPolicyDialog(BuildContext context) {
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
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: theme.cardColor,
              selectedTileColor: theme.cardColor,
              title: Text(
                "プライバシーポリシー",
                style: TextStyle(
                  fontSize: 15,
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PolicyWebViewScreen(
                      url: "https://nb-factory.jp/privacy.html",
                    ),
                  ),
                );
              },
            ),
            ListTile(
              tileColor: theme.cardColor,
              selectedTileColor: theme.cardColor,
              title: Text(
                "利用規約",
                style: TextStyle(
                  fontSize: 15,
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PolicyWebViewScreen(
                      url: "https://nb-factory.jp/terms.html",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        );
      },
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
          const SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 70,
            flexibleSpace: CustomGlassAppBar(title: '設定'),
          ),
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

                      // ⭐ テーマ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: cardTheme.color,
                          elevation: cardTheme.elevation ?? 0,
                          shape: cardTheme.shape,
                          child: ListTile(
                            leading: Icon(Icons.dark_mode, color: onSurface),
                            title: const Text(
                              "テーマ",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _themeLabel(themeProvider.themeMode),
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: onSurface,
                            ),
                            onTap: () =>
                                _showThemeDialog(context, themeProvider),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ⭐ お気に入り削除確認
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: cardTheme.color,
                          elevation: cardTheme.elevation ?? 0,
                          shape: cardTheme.shape,
                          child: ListTile(
                            leading:
                                Icon(Icons.favorite_rounded, color: onSurface),
                            title: const Text(
                              "お気に入り削除時に確認",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _skipDeleteConfirm ? "しない" : "する",
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: onSurface,
                            ),
                            onTap: () => _showDeleteConfirmDialog(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🛒 ショップ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: cardTheme.color,
                          elevation: cardTheme.elevation ?? 0,
                          shape: cardTheme.shape,
                          child: ListTile(
                            leading: Icon(Icons.storefront, color: onSurface),
                            title: const Text(
                              "ショップ",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              "便利な機能でより快適に！",
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: onSurface,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ShopScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📄 各種ポリシー
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: cardTheme.color,
                          elevation: cardTheme.elevation ?? 0,
                          shape: cardTheme.shape,
                          child: ListTile(
                            leading: Icon(Icons.policy, color: onSurface),
                            title: const Text(
                              "各種ポリシー",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              "プライバシー・利用規約",
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: onSurface),
                            onTap: () => _showPolicyDialog(context),
                          ),
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
