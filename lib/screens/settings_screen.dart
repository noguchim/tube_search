import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/policy_webview_screen.dart';
import 'package:tube_search/screens/shop_screen.dart';

import '../data/region_option.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/light_flat_app_bar.dart';

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
    final l = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.dark:
        return l.settingsThemeLabelDark;
      case ThemeMode.light:
        return l.settingsThemeLabelLight;
      default:
        return l.settingsThemeLabelSystem;
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
              label: AppLocalizations.of(context)!.settingsThemeSystem,
              selected: provider.themeMode == ThemeMode.system,
              onTap: () {
                provider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              label: AppLocalizations.of(context)!.settingsThemeLight,
              selected: provider.themeMode == ThemeMode.light,
              onTap: () {
                provider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              label: AppLocalizations.of(context)!.settingsThemeDark,
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
              label: AppLocalizations.of(context)!.settingsFavoriteDeleteOn,
              selected: !_skipDeleteConfirm,
              onTap: () {
                _updateSkipConfirm(false);
                Navigator.pop(context);
              },
            ),
            _buildDeleteOption(
              context,
              label: AppLocalizations.of(context)!.settingsFavoriteDeleteOff,
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
                AppLocalizations.of(context)!.settingsPrivacyPolicy,
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
                AppLocalizations.of(context)!.settingsTerms,
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

  // Phase2対応
  void _showRegionDialog(BuildContext context) {
    final provider = context.read<RegionProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final onSurface = theme.colorScheme.onSurface;

    final sorted = [...regionOptions];
    sorted.sort((a, b) => a.code == provider.regionCode
        ? -1
        : b.code == provider.regionCode
            ? 1
            : 0);

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
            ...sorted.map((r) {
              return ListTile(
                leading: Text(r.flag, style: const TextStyle(fontSize: 20)),
                title: Text(
                  r.label(l),
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: provider.regionCode == r.code
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  provider.setRegion(r.code);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _settingsCard({
    required BuildContext context,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // ✅ 白さ維持のキモ
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05), // ✅ Genreと同じ
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashFactory: InkSparkle.splashFactory,
          onTap: onTap,
          child: ListTile(
            leading: leading,
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
            trailing:
                trailing ?? Icon(Icons.chevron_right_rounded, color: onSurface),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 65,
            flexibleSpace: LightFlatAppBar(
              title: AppLocalizations.of(context)!.settingsTitle,
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 5),

                      // 1️⃣ テーマ
                      _settingsCard(
                        context: context,
                        onTap: () => _showThemeDialog(context, themeProvider),
                        leading:
                            Icon(Icons.brightness_6_outlined, color: onSurface),
                        title: AppLocalizations.of(context)!.settingsTheme,
                        subtitle: _themeLabel(themeProvider.themeMode),
                      ),

                      // 2️⃣ お気に入り削除
                      _settingsCard(
                        context: context,
                        onTap: () => _showDeleteConfirmDialog(context),
                        leading: Icon(Icons.favorite_rounded, color: onSurface),
                        title: AppLocalizations.of(context)!
                            .settingsFavoriteDeleteTitle,
                        subtitle: _skipDeleteConfirm
                            ? AppLocalizations.of(context)!
                                .settingsFavoriteDeleteOff
                            : AppLocalizations.of(context)!
                                .settingsFavoriteDeleteOn,
                      ),

                      // 3️⃣ ショップ
                      _settingsCard(
                        context: context,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShopScreen()),
                          );
                        },
                        leading: Icon(Icons.storefront, color: onSurface),
                        title: AppLocalizations.of(context)!.settingsShop,
                        subtitle:
                            AppLocalizations.of(context)!.settingsShopSubtitle,
                      ),

                      // 4️⃣ 地域（YouTube ランキング）-Phase2
                      // Consumer<RegionProvider>(
                      //   builder: (context, provider, _) {
                      //     final l = AppLocalizations.of(context)!;
                      //     final current = regionOptions
                      //         .firstWhere((r) => r.code == provider.regionCode);
                      //
                      //     return _settingsCard(
                      //       context: context,
                      //       onTap: () => _showRegionDialog(context),
                      //       leading: Icon(Icons.public, color: onSurface),
                      //       title: AppLocalizations.of(context)!.settingsRegion,
                      //       subtitle: "${current.flag}  ${current.label(l)}",
                      //     );
                      //   },
                      // ),

                      // 5️⃣ 各種ポリシー
                      _settingsCard(
                        context: context,
                        onTap: () => _showPolicyDialog(context),
                        leading: Icon(Icons.policy, color: onSurface),
                        title: AppLocalizations.of(context)!.settingsPolicies,
                        subtitle: AppLocalizations.of(context)!
                            .settingsPoliciesSubtitle,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
          )
        ],
      ),
    );
  }
}
