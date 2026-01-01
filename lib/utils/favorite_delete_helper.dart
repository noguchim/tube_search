import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/favorites_service.dart';

class FavoriteDeleteHelper {
  static const String _prefSkipDeleteConfirm = "skip_delete_confirm";

  static Future<void> confirmOrDelete(
    BuildContext context,
    Map<String, dynamic> video,
  ) async {
    // ❶ context を使う処理は先に取得
    final fav = context.read<FavoritesService>();

    // ❷ await が関わる処理
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_prefSkipDeleteConfirm) ?? false;

    // ❸ スキップ → 即削除
    if (skip) {
      await fav.toggle(video["id"], video);
      return;
    }

    // ❹ showDialog の前に mounted 確認
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "お気に入りから削除しますか？",
            style: TextStyle(fontSize: 15, color: onSurface),
          ),
          content: Text(
            "「${video["title"]}」をお気に入りから削除します。",
            style: TextStyle(fontSize: 14, height: 1.5, color: onSurface),
          ),
          actions: [
            TextButton(
              child: Text("キャンセル", style: TextStyle(color: onSurface)),
              onPressed: () => navigator.pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text("削除"),
              onPressed: () async {
                await fav.toggle(video["id"], video);
                navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }
}
