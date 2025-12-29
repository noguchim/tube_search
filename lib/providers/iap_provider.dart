import 'package:flutter/foundation.dart';
import '../services/iap_service.dart';
import '../services/iap_products.dart';

class IapProvider extends ChangeNotifier {
  final IapService _iapService;

  IapProvider(this._iapService);

  IapService get service => _iapService;

  /// 👇 任意の商品が購入済みかどうか（将来商品が増えてもOK）
  bool isPurchased(String productId) {
    return _iapService.isPurchased(productId);
  }

  /// 🔥 起動時に必ず呼ぶ（状態の復元 + purchaseStream 監視開始）
  Future<void> init({
    required void Function(IapProduct product) onPurchased,
    required void Function(String message) onError,
    void Function()? onPending,
  }) async {
    _iapService.onStateChanged = notifyListeners;

    await _iapService.init(
      onPurchased: (product) {
        notifyListeners();   // ← UI 更新
        onPurchased(product); // ← どの商品かを上位へ
      },
      onError: onError,
      onPending: onPending,
    );
  }

  void refresh() {
    notifyListeners();
  }
}
