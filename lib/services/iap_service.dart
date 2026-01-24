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
  Completer<void>? _restoreCompleter;
  Timer? _restoreTimer;
  void Function(String productId)? _onRestoredDuringRestore;

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
      if (_isRestoring &&
          _restoreCompleter != null &&
          !_restoreCompleter!.isCompleted) {
        // restored/purchased/pending/error/canceled いずれでも
        // 「streamが動いた」= restoreの応答が来た と見做して完了
        _restoreCompleter!.complete();
      }

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
              await _markPurchased(product); // ← 状態を反映

              // ✅ restore直後に purchased として来る場合もあるので拾う
              if (_isRestoring) {
                _onRestoredDuringRestore?.call(product.id);
              }

              // ✅ restore中の purchased は「復元」と同等扱いなので UI通知しない
              // （復元ボタン側で1回だけSnackBarを出すため）
              if (!_isRestoring) {
                onPurchased(product); // ← 通常購入だけSnackBar等を出す
              }

              if (p.pendingCompletePurchase) {
                await _iap.completePurchase(p);
              }
              break;

            case PurchaseStatus.restored:
              await _markPurchased(product); // ← 状態は即反映（UIも更新）

              // ✅ restore中に restored が来たら記録
              if (_isRestoring) {
                _onRestoredDuringRestore?.call(product.id);
              }

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

        // ✅ restore中で、今回purchaseStreamが空でなく何か来たなら
        // 全件処理し終わってから restore完了扱いにする
        if (_isRestoring &&
            purchases.isNotEmpty &&
            _restoreCompleter != null &&
            !_restoreCompleter!.isCompleted) {
          _restoreCompleter!.complete();
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
  /// restoreした結果「今回 newly purchased 扱いになった productId 一覧」を返す
  Future<List<String>> restore() async {
    logger.i('[IAP] RESTORE start');

    // ✅ 連打対策（復元中ならスキップ）
    if (_isRestoring) {
      logger.w('[IAP] RESTORE skipped (already restoring)');
      return const [];
    }

    _isRestoring = true;

    // 今回restoreで restored/purchased が来たものを記録
    final restoredIds = <String>{};

    // ✅ 前回のrestoreが残っている場合だけ完了させる（complete済みにcompleteしない）
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete();
    }
    _restoreCompleter = Completer<void>();

    _restoreTimer?.cancel();
    _restoreTimer = Timer(const Duration(seconds: 2), () {
      if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
        logger.w('[IAP] RESTORE timeout (no stream event)');
        _restoreCompleter!.complete();
      }
    });

    // ✅ restore中だけ purchaseStream の処理でここに溜めるためのフラグ
    void addRestored(String id) => restoredIds.add(id);

    // ✅ temporarily set callback
    _onRestoredDuringRestore = addRestored;

    try {
      await _iap.restorePurchases();

      // ✅ purchaseStream側で complete されるのを待つ
      await _restoreCompleter!.future;

      logger.i('[IAP] RESTORE collected ids: ${restoredIds.toList()}');
      return restoredIds.toList();
    } catch (e) {
      logger.e('[IAP] RESTORE failed', error: e);
      return const [];
    } finally {
      _onRestoredDuringRestore = null;

      _restoreTimer?.cancel();
      _restoreTimer = null;

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
