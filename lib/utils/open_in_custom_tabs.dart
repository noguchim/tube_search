import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import '../l10n/app_localizations.dart';
import '../data/youtube_playback_close_reason.dart';
import '../screens/youtube_webview_screen.dart';
import '../services/playback_progress_service.dart';

/// YouTubeを「アプリでは開かず」
/// - Android: WebView（inAppWebView）
/// - iOS: SafariViewController
///
/// 👉 CustomTabsは使わない（戻るバグ対策）
Future<YouTubePlaybackCloseReason?> openYouTubeInInAppBrowser(
  BuildContext context, {
  required String videoId,
  int startSeconds = 0,
  int? durationSeconds,
  Duration? autoCloseAfter,
  bool useSavedProgress = true,
  bool trackProgress = true,
}) async {
  final t = AppLocalizations.of(context)!;
  final progressService = context.read<PlaybackProgressService>();
  final savedStart = useSavedProgress
      ? await progressService.resumeSeconds(
          videoId,
          durationSeconds: durationSeconds,
        )
      : 0;
  final effectiveStart = savedStart > startSeconds ? savedStart : startSeconds;
  final openedAt = DateTime.now();
  if (!context.mounted) return null;

  // 🔥 安定URL（アプリ遷移抑制）
  final webUrl = Uri.https('www.youtube.com', '/watch', {
    'v': videoId,
    'bpctr': '9999999999',
    'has_verified': '1',
    if (effectiveStart > 0) 't': '${effectiveStart}s',
  });

  try {
    if (Platform.isAndroid) {
      final reason = await Navigator.push<YouTubePlaybackCloseReason>(
        context,
        MaterialPageRoute(
          builder: (_) => YouTubeWebViewScreen(
            url: webUrl.toString(),
            autoCloseAfter: autoCloseAfter,
          ),
        ),
      );
      if (trackProgress &&
          reason != YouTubePlaybackCloseReason.externalApplication) {
        await _savePlaybackProgress(
          progressService,
          videoId: videoId,
          startSeconds: effectiveStart,
          durationSeconds: durationSeconds,
          openedAt: openedAt,
          completed: reason == YouTubePlaybackCloseReason.automatic,
        );
      }
      return reason;
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
      if (trackProgress) {
        await _savePlaybackProgress(
          progressService,
          videoId: videoId,
          startSeconds: effectiveStart,
          durationSeconds: durationSeconds,
          openedAt: openedAt,
        );
      }
      return null;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.browserOpenFailed)));
      }
    } catch (e2) {
      debugPrint('[openYouTubeInInAppBrowser] fallback failed: $e2');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.browserOpenFailed)));
      }
    }
  }
  return null;
}

Future<void> _savePlaybackProgress(
  PlaybackProgressService service, {
  required String videoId,
  required int startSeconds,
  required int? durationSeconds,
  required DateTime openedAt,
  bool completed = false,
}) async {
  if (completed && durationSeconds != null && durationSeconds > 0) {
    await service.markCompleted(videoId, durationSeconds: durationSeconds);
    return;
  }

  final elapsed = DateTime.now().difference(openedAt).inSeconds;
  await service.saveProgress(
    videoId,
    progressSeconds: startSeconds + elapsed,
    durationSeconds: durationSeconds,
  );
}
