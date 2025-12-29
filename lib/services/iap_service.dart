// lib/services/iap_service.dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import 'iap_products.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isRestoring = false;
  bool _initialized = false;

  /// 👇 UI と同期させるためのフック（Provider が設定する）
  void Function()? onStateChanged;

  /// メモリ上の購入状態
  final Map<String, bool> purchased = {};

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  Future<void> init({
    required void Function(IapProduct product) onPurchased,
    required void Function(String message) onError,
    void Function()? onPending,
  }) async {
    if (_initialized) {
      logger.i('[IAP] init skipped (already initialized)');
      return;
    }
    _initialized = true;

    logger.i('[IAP] init start');

    // 保存から復元
    final prefs = await SharedPreferences.getInstance();
    for (final p in IapProducts.all) {
      final value = prefs.getBool(p.prefKey) ?? false;
      purchased[p.id] = value;
      logger.i('[IAP] restore(local): ${p.id} = $value');
    }

    final available = await _iap.isAvailable();
    if (!available) {
      onError('In-app purchase is not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
          (purchases) async {
        logger.i('[IAP] purchaseStream: ${purchases.length} events');

        for (final p in purchases) {
          final product = IapProducts.byId(p.productID);
          if (product == null) {
            logger.w('[IAP] unknown product: ${p.productID}');
            continue;
          }

          logger.i('[IAP] ${p.productID} / ${p.status}');

          switch (p.status) {
            case PurchaseStatus.purchased:
              await _markPurchased(product);   // ← 状態を反映
              onPurchased(product);           // ← Snackbar などだけ
              if (p.pendingCompletePurchase) {
                await _iap.completePurchase(p);
              }
              break;

            case PurchaseStatus.restored:
              await _markPurchased(product);   // ← 状態は即反映（UIも更新）
              if (p.pendingCompletePurchase) {
                await _iap.completePurchase(p);
              }
              break;

            case PurchaseStatus.pending:
              onPending?.call();
              break;

            case PurchaseStatus.canceled:
              onError('購入がキャンセルされました');
              break;

            case PurchaseStatus.error:
              onError(p.error?.message ?? '購入中にエラーが発生しました');
              break;
          }
        }
      },
      onError: (e) {
        logger.e('[IAP] stream error', error: e);
        onError(e.toString());
      },
    );
  }

  // ------------------------------------------------------------
  // PRODUCT
  // ------------------------------------------------------------
  Future<ProductDetails?> loadProduct(String productId) async {
    logger.i('[IAP] query: $productId');

    final res = await _iap.queryProductDetails({productId});

    if (res.error != null) {
      logger.e('[IAP] query error', error: res.error);
    }

    return res.productDetails.isEmpty ? null : res.productDetails.first;
  }

  // ------------------------------------------------------------
  // BUY
  // ------------------------------------------------------------
  Future<void> buy(ProductDetails product) async {
    logger.i('[IAP] BUY start: ${product.id}');
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      logger.i('[IAP] BUY request sent');
    } catch (e) {
      logger.e('[IAP] BUY failed', error: e);
    }
  }

  // ------------------------------------------------------------
  // RESTORE
  // ------------------------------------------------------------
  Future<void> restore() async {
    logger.i('[IAP] RESTORE start');
    _isRestoring = true;
    try {
      await _iap.restorePurchases();
    } finally {
      _isRestoring = false;
      logger.i('[IAP] RESTORE finished');
    }
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------
  Future<void> _markPurchased(IapProduct product) async {
    purchased[product.id] = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(product.prefKey, true);

    logger.i('[IAP] marked purchased: ${product.id}');

    // 👇 状態が変わった瞬間 UI へ通知（購入・復元どちらでも）
    onStateChanged?.call();
  }

  bool isPurchased(String id) => purchased[id] ?? false;

  void dispose() {
    _subscription?.cancel();
  }
}
