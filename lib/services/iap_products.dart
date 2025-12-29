// lib/services/iap_products.dart

class IapProduct {
  final String id;        // App Store の Product ID
  final String prefKey;   // 購入状態を保存するキー
  final String displayName;      // UI 表示用の名前
  final String purchaseMessage;  // 購入後に表示するメッセージ

  const IapProduct({
    required this.id,
    required this.prefKey,
    required this.displayName,
    required this.purchaseMessage,
  });
}

/// 🎁 すべての IAP 商品をここで一元管理
class IapProducts {
  /// 🟥 広告削除
  static const removeAds = IapProduct(
    id: 'remove_ads',
    prefKey: 'iap_remove_ads',
    displayName: '広告削除',
    purchaseMessage: '広告を削除しました',
  );

  /// 🟦 上限拡張（NEW）
  static const limitUpgrade = IapProduct(
    id: 'limit_upgrade',
    prefKey: 'iap_limit_upgrade',
    displayName: '上限拡張',
    purchaseMessage: '上限を拡張しました（5倍！）',
  );

  /// 🔗 一覧（ループ・検索用）
  static const List<IapProduct> all = [
    removeAds,
    limitUpgrade,
  ];

  /// 🔍 productId から商品を取得（見つからない場合は null）
  static IapProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
