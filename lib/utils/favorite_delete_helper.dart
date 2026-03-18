import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../services/favorites_service.dart';
import '../widgets/app_dialog.dart';

class FavoriteDeleteHelper {
  static const String _prefSkipDeleteConfirm = "skip_delete_confirm";

  static Future<void> confirmOrDelete(
    BuildContext context,
    YouTubeVideo video,
  ) async {
    // ❶ context を使う処理は先に取得
    final fav = context.read<FavoritesService>();

    // ❷ await が関わる処理
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_prefSkipDeleteConfirm) ?? false;

    // ❸ スキップ → 即削除
    if (skip) {
      await fav.toggle(video.id, video);
      return;
    }

    // ❹ showDialog の前に mounted 確認
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppDialog(
          title: AppLocalizations.of(context)!.favoriteDeleteTitle,
          message: AppLocalizations.of(context)!.favoriteDeleteMessage(
            video.title ?? "",
          ),
          style: AppDialogStyle.danger, // ← 削除なので危険色
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                AppLocalizations.of(context)!.favoriteDeleteCancel,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                // 🔥 赤固定（danger）
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold, // ← ★ 強調
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await fav.toggle(video.id, video);
                navigator.pop();
              },
              child: Text(AppLocalizations.of(context)!.favoriteDeleteConfirm),
            ),
            const SizedBox(width: 10),
          ],
        );
      },
    );
  }
}
