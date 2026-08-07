// lib/services/iap_products.dart

class IapProduct {
  final String id;
  final String prefKey;

  // ← L10N のキーを保存する（生テキストではない）
  final String displayNameKey;
  final String purchaseMessageKey;

  const IapProduct({
    required this.id,
    required this.prefKey,
    required this.displayNameKey,
    required this.purchaseMessageKey,
  });
}

/// 🎁 すべての IAP 商品をここで一元管理
class IapProducts {
  /// 🟥 広告削除
  static const removeAds = IapProduct(
    id: 'remove_ads',
    prefKey: 'iap_remove_ads',
    displayNameKey: 'iapRemoveAdsName',
    purchaseMessageKey: 'iapRemoveAdsPurchased',
  );

  /// 🟦 上限拡張（NEW）
  static const limitUpgrade = IapProduct(
    id: 'limit_upgrade',
    prefKey: 'iap_limit_upgrade',
    displayNameKey: 'iapLimitUpgradeName',
    purchaseMessageKey: 'iapLimitUpgradePurchased',
  );

  /// 続けて視聴PRO
  static const continueWatchPro = IapProduct(
    id: 'continue_watch_pro_v1',
    prefKey: 'iap_continue_watch_pro_v1',
    displayNameKey: 'iapContinueWatchProName',
    purchaseMessageKey: 'iapContinueWatchProPurchased',
  );

  /// 🔗 一覧（ループ・検索用）
  static const List<IapProduct> all = [
    removeAds,
    limitUpgrade,
    continueWatchPro,
  ];

  /// 🔍 productId から商品を取得（見つからない場合は null）
  static IapProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
