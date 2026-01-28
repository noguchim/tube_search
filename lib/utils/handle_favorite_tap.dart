import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../screens/shop_screen.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../widgets/app_dialog.dart';
import 'favorite_delete_helper.dart';

Future<void> handleFavoriteTap(
  BuildContext context, {
  required Map<String, dynamic> video,
}) async {
  final fav = context.read<FavoritesService>();
  final iap = context.read<IapProvider>();

  final id = video['id']?.toString() ?? '';
  if (id.isEmpty) return;

  // すでにお気に入り → 削除確認
  if (fav.isFavoriteSync(id)) {
    await FavoriteDeleteHelper.confirmOrDelete(
      context,
      video,
    );
    return;
  }

  // 追加トライ
  final ok = await fav.tryAddFavorite(id, video, iap);

  if (!ok) {
    _showFavoriteLimitDialog(context, iap);
  }
}

void _showFavoriteLimitDialog(
  BuildContext context,
  IapProvider iap,
) {
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
            child: Text(t.favoriteLimitClose),
          ),
          if (!purchased)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                );
              },
              child: Text(t.favoriteLimitUpgrade),
            ),
        ],
      );
    },
  );
}
