import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../screens/shop_screen.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../widgets/app_dialog.dart';
import 'favorite_delete_helper.dart';

Future<void> handleFavoriteTap(
  BuildContext context, {
  required YouTubeVideo video,
}) async {
  final fav = context.read<FavoritesService>();
  final iap = context.read<IapProvider>();

  final id = video.id;
  if (id.isEmpty) return;

  // =========================
  // ❤️ すでにお気に入り
  // =========================
  if (fav.isFavoriteSync(id)) {
    // 🔒 ロック中
    if (fav.isLockedSync(id)) {
      await _showLockedFavoriteDialog(context);
      return;
    }

    // 🔓 削除確認
    await FavoriteDeleteHelper.confirmOrDelete(
      context,
      video,
    );

    return;
  }

  // =========================
  // ❤️ 追加
  // =========================
  final ok = await fav.tryAddFavorite(id, video, iap);

  if (!context.mounted) return;

  if (!ok) {
    _showFavoriteLimitDialog(context, iap);
  }
}

Future<void> _showLockedFavoriteDialog(BuildContext context) async {
  final t = AppLocalizations.of(context)!;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (_) {
      return AppDialog(
        title: t.favoriteLockedTitle,
        message: t.favoriteLockedMessage,
        style: AppDialogStyle.info,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.buttonOk,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _showFavoriteLimitDialog(
  BuildContext context,
  IapProvider iap,
) {
  if (!context.mounted) return;

  final purchased = iap.isPurchased(IapProducts.limitUpgrade.id);
  final t = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (_) {
      return AppDialog(
        title: t.favoriteLimitTitle,
        message:
            purchased ? t.favoriteLimitPurchased : t.favoriteLimitNotPurchased,
        style: AppDialogStyle.info,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.favoriteLimitClose,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (!purchased)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShopScreen(),
                  ),
                );
              },
              child: Text(t.favoriteLimitUpgrade),
            ),
        ],
      );
    },
  );
}
