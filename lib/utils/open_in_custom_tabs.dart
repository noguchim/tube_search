import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;
import 'package:url_launcher/url_launcher.dart' as ul;

import '../l10n/app_localizations.dart';
import '../screens/youtube_webview_screen.dart';

/// YouTubeを「アプリでは開かず」
/// - Android: WebView（inAppWebView）
/// - iOS: SafariViewController
///
/// 👉 CustomTabsは使わない（戻るバグ対策）
Future<void> openYouTubeInInAppBrowser(
  BuildContext context, {
  required String videoId,
}) async {
  final t = AppLocalizations.of(context)!;

  // 🔥 安定URL（アプリ遷移抑制）
  final webUrl = Uri.parse(
    'https://www.youtube.com/watch?v=$videoId&bpctr=9999999999&has_verified=1',
  );

  try {
    if (Platform.isAndroid) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YouTubeWebViewScreen(
            url: webUrl.toString(),
          ),
        ),
      );
      return;
    } else {
      // =========================
      // 🍎 iOS → SafariViewController
      // =========================
      await ct.launchUrl(
        webUrl,
        safariVCOptions: const ct.SafariViewControllerOptions(
          barCollapsingEnabled: true,
          dismissButtonStyle: ct.SafariViewControllerDismissButtonStyle.close,
        ),
      );
    }
  } catch (e) {
    debugPrint('[openYouTubeInInAppBrowser] error: $e');

    // =========================
    // 🛟 フォールバック（最終手段）
    // =========================
    try {
      final ok = await ul.launchUrl(
        webUrl,
        mode: ul.LaunchMode.externalApplication,
      );

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.browserOpenFailed)),
        );
      }
    } catch (e2) {
      debugPrint('[openYouTubeInInAppBrowser] fallback failed: $e2');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.browserOpenFailed)),
        );
      }
    }
  }
}
