import '../providers/iap_provider.dart';
import '../services/iap_products.dart';

/// アプリ内の「件数上限」を一括管理するクラス
class LimitService {
  /// 🔹 動画一覧の最大件数
  static int videoListLimit(IapProvider iap) {
    return iap.isPurchased(IapProducts.limitUpgrade.id)
        ? 50 // ← 上限拡張（購入済み）
        : 20; // ← 無料版
  }

  /// 🔹 お気に入りの最大件数
  static int favoritesLimit(IapProvider iap) {
    return iap.isPurchased(IapProducts.limitUpgrade.id) ? 50 : 20;
  }
}
