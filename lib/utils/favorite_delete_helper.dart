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

    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) {
        return AppDialog(
          title: AppLocalizations.of(context)!.favoriteDeleteTitle,
          message: AppLocalizations.of(context)!.favoriteDeleteMessage(
            video.title,
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                AppLocalizations.of(context)!.favoriteDeleteCancel,
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
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
