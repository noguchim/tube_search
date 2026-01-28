import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../screens/shop_screen.dart';
import '../services/iap_products.dart';
import '../widgets/app_dialog.dart';

void showLimitDialog(BuildContext context, IapProvider iap) {
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
            child: Text(t.favoriteLimitClose),
            onPressed: () => Navigator.pop(context),
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
