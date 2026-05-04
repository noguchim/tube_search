import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/policy_webview_screen.dart';
import 'package:tube_search/screens/shop_screen.dart';
import 'package:tube_search/screens/watch_history_screen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../data/region_option.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

String localizedPage(BuildContext context, String page) {
  final locale = Localizations.localeOf(context).languageCode;

  if (locale == 'ja') {
    return "https://nb-factory.jp/$page.html?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  return "https://nb-factory.jp/${page}_en.html?t=${DateTime.now().millisecondsSinceEpoch}";
}

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeProvider = context.watch<ThemeProvider>();
    final regionProvider = context.watch<RegionProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final logic = SettingsLogic(context);
    final l = AppLocalizations.of(context)!;

    // =========================
    // 🔥 ヘッダカラー
    // =========================
    final headerColor =
        isDark ? const Color(0xAA000000) : const Color(0xFF282828);

    // =========================
    // 🔥 Divider
    // =========================
    Widget divider() {
      return Divider(
        height: 20,
        thickness: 0.6,
        color: Colors.grey.withValues(alpha: 0.5),
      );
    }

    // =========================
    // 🔥 アイテム
    // =========================
    Widget item(
      BuildContext context, {
      required IconData icon,
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      final onSurface = Theme.of(context).colorScheme.onSurface;

      return ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
        onTap: onTap,
      );
    }

    // for Phase2
    // String countryName() {
    //   final region = regionProvider.regionCode;
    //
    //   switch (region) {
    //     case "JP":
    //       return l.regionJapan;
    //     case "US":
    //       return l.regionUnitedStates;
    //     case "GB":
    //       return l.regionUnitedKingdom;
    //
    //     // 🌍 fallback
    //     default:
    //       return region; // or "Global"
    //   }
    // }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // =========================
          // 🔥 ヘッダ
          // =========================
          Container(
            width: double.infinity,
            height: 100,
            padding: const EdgeInsets.only(left: 0, right: 12, bottom: 4),
            alignment: Alignment.bottomLeft,
            color: headerColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🍔 ハンバーガー（閉じる）
                IconButton(
                  icon: const Icon(Icons.menu),
                  iconSize: 26,
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pop(context); // ← ドロワー閉じる
                  },
                ),

                // 🟩 ロゴ
                Image.asset(
                  'assets/images/logo.png',
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // =========================
          // 🔥 本体
          // =========================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                item(
                  context,
                  icon: Icons.brightness_6_outlined,
                  title: l.settingsTheme,
                  value: logic.themeLabel(themeProvider.themeMode),
                  onTap: () {
                    logic.showThemeDialog(context, themeProvider);
                  },
                ),
                item(
                  context,
                  icon: Icons.favorite_border,
                  title: l.settingsFavoriteDeleteTitle,
                  value: settingsProvider.label,
                  onTap: () => logic.showDeleteConfirmDialog(context),
                ),
                item(
                  context,
                  icon: Icons.history,
                  title: "視聴履歴",
                  value: "",
                  onTap: () {
                    Navigator.of(context).pop(); // 先にドロワーを閉じる
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WatchHistoryScreen(),
                      ),
                    );
                  },
                ),

                // for Phase2
                // divider(),
                //
                // item(
                //   context,
                //   icon: Icons.public,
                //   title: l.settingsRegion,
                //   value: countryName(),
                //   onTap: () => logic.showRegionDialog(context),
                // ),

                divider(),

                item(
                  context,
                  icon: Icons.storefront,
                  title: l.settingsShop,
                  value: l.settingsShopSubtitle,
                  onTap: () {
                    Navigator.of(context).pop(); // 先にドロワーを閉じる
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                  },
                ),

                divider(),

                item(
                  context,
                  icon: Icons.trending_up,
                  title: l.aboutRankingCalculation,
                  value: "",
                  onTap: () {
                    Navigator.of(context).pop(); // 先にドロワーを閉じる
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PolicyWebViewScreen(
                          url: localizedPage(context, "popularity"),
                        ),
                      ),
                    );
                  },
                ),
                item(
                  context,
                  icon: Icons.policy,
                  title: l.settingsPolicies,
                  value: "",
                  onTap: () => logic.showPolicyDialog(context),
                ),
                item(
                  context,
                  icon: Icons.info_outline,
                  title: l.settingsAbout,
                  value: "",
                  onTap: () => logic.showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsLogic {
  final BuildContext context;

  SettingsLogic(this.context);

  bool skipDeleteConfirm = false;
  bool loading = true;
  static const String _prefSkipDeleteConfirm = "skip_delete_confirm";

  String themeLabel(ThemeMode mode) {
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

  Future<String> deleteLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool("skip_delete_confirm") ?? false;

    return value ? "確認しない" : "確認する";
  }

  // -------------------------------------------------------------------
  // 🔥 テーマ変更ダイアログ
  // -------------------------------------------------------------------
  void showThemeDialog(BuildContext context, ThemeProvider provider) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

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
              label: l.settingsThemeSystem,
              selected: provider.themeMode == ThemeMode.system,
              onTap: () {
                provider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              label: l.settingsThemeLight,
              selected: provider.themeMode == ThemeMode.light,
              onTap: () {
                provider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              label: l.settingsThemeDark,
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
  void showDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.read<SettingsProvider>();

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
              label: "確認する",
              selected: !settingsProvider.skipDeleteConfirm,
              onTap: () {
                settingsProvider.update(false);
                Navigator.pop(context);
              },
            ),
            _buildDeleteOption(
              context,
              label: "確認しない",
              selected: settingsProvider.skipDeleteConfirm,
              onTap: () {
                settingsProvider.update(true);
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

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    skipDeleteConfirm = prefs.getBool("skip_delete_confirm") ?? false;

    loading = false;
  }

  Future<void> updateSkipConfirm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSkipDeleteConfirm, value);

    loading = false;
  }

  void showPolicyDialog(BuildContext context) {
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
                    builder: (_) => PolicyWebViewScreen(
                      url: localizedPage(context, "privacy"),
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
                    builder: (_) => PolicyWebViewScreen(
                      url: localizedPage(context, "terms"),
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

  void showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.6, // 🔥 高さ制限（ここ調整）
            ),
            child: SingleChildScrollView(
              child: Column(
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
                    title: const Text(
                      "Tube Plus",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: FutureBuilder(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text("");
                        final info = snapshot.data as PackageInfo;
                        return Text("Version ${info.version}");
                      },
                    ),
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.trending_up),
                  //   title: Text(
                  //     l.aboutRankingCalculation,
                  //     style: const TextStyle(
                  //       fontSize: 15,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  //   trailing: const Icon(Icons.chevron_right),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => PolicyWebViewScreen(
                  //           url: localizedPage(context, "popularity"),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text("NB FACTORY"),
                    subtitle: const Text("Developer website"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PolicyWebViewScreen(
                            url:
                                "https://nb-factory.jp/?t=${DateTime.now().millisecondsSinceEpoch}",
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Platform.isIOS ? Icons.apple : Icons.android,
                    ),
                    title: Text(
                      Platform.isIOS ? "App Store" : "Google Play",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final uri = Platform.isIOS
                          ? Uri.parse(
                              "https://apps.apple.com/app/tube/id6756842201")
                          : Uri.parse(
                              "https://play.google.com/store/apps/details?id=jp.nbfactory.tubesearch.app");

                      await url_launcher.launchUrl(
                        uri,
                        mode: url_launcher.LaunchMode.externalApplication,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showRankingPage(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PolicyWebViewScreen(
          url: localizedPage(context, "popularity"),
        ),
      ),
    );
  }

  void showRegionDialog(BuildContext context) {
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
}
