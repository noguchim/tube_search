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
          // 🪩 共通ガラスAppBar
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 65,
            flexibleSpace: const CustomGlassAppBar(
              title: '設定',
            ),
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
                // ⭐ テーマ設定セクション
                // ------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "テーマ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Material(
                  color: cardTheme.color,
                  elevation: cardTheme.elevation ?? 0,
                  shape: cardTheme.shape,
                  child: SwitchListTile(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    title: Text(
                      "ダークテーマ",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "ON にするとアプリ全体がダークモードになります。",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                    onChanged: (value) {
                      themeProvider.setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
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
                      color: onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Material(
                  color: cardTheme.color,
                  elevation: cardTheme.elevation ?? 0,
                  shape: cardTheme.shape,
                  child: SwitchListTile(
                    value: !_skipDeleteConfirm,
                    title: Text(
                      "削除時に確認ダイアログを表示",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "OFF にするとお気に入り削除時の確認を省略します。",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                    onChanged: (v) => _updateSkipConfirm(!v),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
