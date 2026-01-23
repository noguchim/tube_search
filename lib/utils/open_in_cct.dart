import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

Future<void> openYouTubeInCCT(
  BuildContext context, {
  required String videoId,
}) async {
  final url = 'https://m.youtube.com/watch?v=$videoId';

  try {
    await launchUrl(
      Uri.parse(url),
      customTabsOptions: CustomTabsOptions(
        // 見た目
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: Colors.black,
        ),
        showTitle: true,
        // UX
        shareState: CustomTabsShareState.on,
        urlBarHidingEnabled: true,
      ),
      safariVCOptions: const SafariViewControllerOptions(
        // iOSでも同じ体験にできる
        barCollapsingEnabled: true,
      ),
    );
  } catch (e) {
    // ここで url_launcher へのフォールバック入れてもOK
    debugPrint('openYouTubeInCCT error: $e');
    rethrow;
  }
}
