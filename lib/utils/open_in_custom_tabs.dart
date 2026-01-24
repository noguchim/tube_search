import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;
import 'package:url_launcher/url_launcher.dart' as ul;

/// YouTubeを「アプリでは開かず」
/// 常に内製ブラウザ（Android: Custom Tabs / iOS: SafariViewController）で開く。
///
/// - Phase2（連続再生）を考えると、この挙動が最も安定
/// - 公式YouTubeアプリで開くボタンはページ側に出るため、導線は担保される
Future<void> openYouTubeInInAppBrowser(
  BuildContext context, {
  required String videoId,
}) async {
  // ✅ m.youtube.com の方がモバイルUIで安定しやすい
  // watch は維持しつつ、短縮URLより安定することが多い
  final webUrl = Uri.parse('https://m.youtube.com/watch?v=$videoId');

  // ① まず内製ブラウザで開く（常にこれ）
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
    debugPrint('[openYouTubeInInAppBrowser] CustomTabs/SafariVC failed: $e');
  }

  // ② フォールバック：外部ブラウザ（端末既定ブラウザ）
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
    debugPrint('[openYouTubeInInAppBrowser] external browser failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブラウザを開けませんでした')),
      );
    }
  }
}
