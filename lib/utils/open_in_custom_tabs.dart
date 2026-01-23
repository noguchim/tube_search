// import 'package:flutter/material.dart';
// import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
//
// Future<void> openYouTubeInCustomTabs(
//   BuildContext context, {
//   required String videoId,
// }) async {
//   // ✅ m.youtube.com の方がモバイルUIで安定しやすい
//   final url = "https://m.youtube.com/watch?v=$videoId";
//
//   await launchUrl(
//     Uri.parse(url),
//     customTabsOptions: CustomTabsOptions(
//       showTitle: true,
//       urlBarHidingEnabled: true,
//       shareState: CustomTabsShareState.on,
//
//       // 好みで調整（TUBE+は黒系なので）
//       colorSchemes: CustomTabsColorSchemes.defaults(
//         toolbarColor: Colors.black,
//       ),
//     ),
//     safariVCOptions: const SafariViewControllerOptions(
//       barCollapsingEnabled: true,
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;
import 'package:url_launcher/url_launcher.dart' as ul;

Future<void> openYouTubePreferApp(
  BuildContext context, {
  required String videoId,
}) async {
  final youtubeAppUrl = Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
  final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

  // 1) YouTubeアプリがあれば最優先
  try {
    final canOpenApp = await ul.canLaunchUrl(youtubeAppUrl);
    if (canOpenApp) {
      final ok = await ul.launchUrl(
        youtubeAppUrl,
        mode: ul.LaunchMode.externalApplication,
      );
      if (ok) return;
    }
  } catch (e) {
    debugPrint('[openYouTubePreferApp] open youtube app failed: $e');
  }

  // 2) 次に内製ブラウザ（Android: Custom Tabs / iOS: SafariVC）
  try {
    await ct.launchUrl(
      webUrl,
      customTabsOptions: ct.CustomTabsOptions(
        showTitle: true,
        urlBarHidingEnabled: true,
        shareState: ct.CustomTabsShareState.on,
        colorSchemes: ct.CustomTabsColorSchemes.defaults(
          toolbarColor: Colors.black,
        ),
      ),
      safariVCOptions: const ct.SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: ct.SafariViewControllerDismissButtonStyle.close,
      ),
    );
    return;
  } catch (e) {
    debugPrint('[openYouTubePreferApp] CustomTabs/SafariVC failed: $e');
  }

  // 3) 最後に外部ブラウザ
  try {
    final ok = await ul.launchUrl(
      webUrl,
      mode: ul.LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブラウザを開けませんでした')),
      );
    }
  } catch (e) {
    debugPrint('[openYouTubePreferApp] external browser failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブラウザを開けませんでした')),
      );
    }
  }
}
