import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../services/iap_products.dart';
import '../utils/app_logger.dart';
import '../widgets/network_error_view.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool isProcessing = false;
  bool _lastRemoveAds = false;
  bool _lastLimit = false;
  IapProvider? _provider;
  String _priceRemove = "—";
  String _priceLimit = "—";
  bool _hasError = false;
  bool _isLoading = true;
  bool _suppressIapSnack = false;

  @override
  void initState() {
    super.initState();

    _provider = context.read<IapProvider>();

    _lastRemoveAds = _provider!.isPurchased(IapProducts.removeAds.id);
    _lastLimit = _provider!.isPurchased(IapProducts.limitUpgrade.id);

    _provider!.addListener(_onIapChanged);

    _loadPrices();
  }

  Future<bool> _checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('apple.com')
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadPrices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // ① ネットワーク健全性チェック
    final ok = await _checkNetwork();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    // ② 価格取得
    try {
      final iap = context.read<IapProvider>().service;

      final pRemove = await iap.loadProduct(IapProducts.removeAds.id);
      final pLimit = await iap.loadProduct(IapProducts.limitUpgrade.id);

      if (!mounted) return;

      // ③ 両方取得できないならエラー扱い
      if (pRemove == null || pLimit == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _priceRemove = pRemove.price;
        logger.i("[_loadPrices] _priceRemove = $_priceRemove");
        _priceLimit = pLimit.price;
        logger.i("[_loadPrices] _priceLimit = $_priceLimit");
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _retry() {
    _loadPrices();
  }

  void _onIapChanged() {
    final provider = context.read<IapProvider>();
    final t = AppLocalizations.of(context)!;

    final remove = provider.isPurchased(IapProducts.removeAds.id);
    final limit = provider.isPurchased(IapProducts.limitUpgrade.id);

    // ✅ 復元中は「個別購入メッセージ」を出さない（復元ボタン側で1回だけ出す）
    if (_suppressIapSnack) {
      logger.i("復元中ルート → return");
      _lastRemoveAds = remove;
      _lastLimit = limit;
      return;
    } else {
      logger.i("通常MSGルート → 各MSG");
    }

    if (!_lastRemoveAds && remove) {
      _showSnack(
        _resolveMessage(t, IapProducts.removeAds.purchaseMessageKey),
      );
    }

    if (!_lastLimit && limit) {
      _showSnack(
        _resolveMessage(t, IapProducts.limitUpgrade.purchaseMessageKey),
      );
    }

    _lastRemoveAds = remove;
    _lastLimit = limit;
  }

  String _resolveMessage(AppLocalizations t, String key) {
    switch (key) {
      case 'iapRemoveAdsPurchased':
        return t.shopPurchasedRemoveAds; // ← 既存 L10N に合わせて調整
      case 'iapLimitUpgradePurchased':
        return t.shopPurchasedLimit;
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onIapChanged);
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // 👇 購入状態を Provider から取得（将来商品が増えても安全）
    final removeAdsPurchased =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);
    final limitUpgradePurchased =
        context.watch<IapProvider>().isPurchased(IapProducts.limitUpgrade.id);

    return Scaffold(
      body: Stack(
        children: [
          // ① ベース背景
          Container(color: const Color(0xFF0E1A2B)),

          // ② 上部ライト
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(70, 120, 160, 220),
                  Color.fromARGB(0, 120, 160, 220),
                ],
              ),
            ),
          ),

          // ③ 中身
          SafeArea(
            child: Stack(
              children: [
                // =========================
                // 🚨 ネットワークエラー
                // =========================
                if (_hasError)
                  Stack(
                    children: [
                      Container(
                        color: const Color(0xFFFAF5EF),
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: NetworkErrorView(onRetry: _retry),
                        ),
                      ),

                      // ← 戻る
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )

                // =========================
                // ⏳ ローディング
                // =========================
                else if (_isLoading)
                  const Center(child: CircularProgressIndicator())

                // =========================
                // 🎁 通常ショップ表示
                // =========================
                else
                  Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
                        children: [
                          // ===== 広告削除 =====
                          ShopListCard(
                            icon: Icons.ads_click,
                            title: AppLocalizations.of(context)!
                                .shopTitleRemoveAds,
                            description:
                                AppLocalizations.of(context)!.shopDescRemoveAds,
                            enabled: !removeAdsPurchased,
                            purchased: removeAdsPurchased,
                            iconColor: Theme.of(context).colorScheme.primary,
                            priceLabel: _priceRemove,
                            minHeight: 80,
                            onBuy: removeAdsPurchased
                                ? null
                                : () async {
                                    logger.i('[UI] Buy tapped');
                                    setState(() => isProcessing = true);
                                    try {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final iap =
                                          context.read<IapProvider>().service;

                                      final product = await iap.loadProduct(
                                          IapProducts.removeAds.id);
                                      if (product == null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .shopLoadFailed,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      await iap.buy(product);
                                    } finally {
                                      if (mounted) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                          ),

                          const SizedBox(height: 16),

                          // ===== 上限拡張 =====
                          ShopListCard(
                            icon: Icons.upgrade,
                            title: AppLocalizations.of(context)!.shopTitleLimit,
                            description:
                                AppLocalizations.of(context)!.shopDescLimit,
                            enabled: !limitUpgradePurchased,
                            purchased: limitUpgradePurchased,
                            iconColor: const Color(0xFF9B59B6),
                            priceLabel: _priceLimit,
                            minHeight: 80,
                            onBuy: limitUpgradePurchased
                                ? null
                                : () async {
                                    logger.i('[UI] Buy tapped (limit_upgrade)');
                                    setState(() => isProcessing = true);
                                    try {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final iap =
                                          context.read<IapProvider>().service;

                                      final product = await iap.loadProduct(
                                          IapProducts.limitUpgrade.id);
                                      if (product == null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .shopLoadFailed,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      await iap.buy(product);
                                    } finally {
                                      if (mounted) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                          ),

                          const SizedBox(height: 16),

                          // ===== 連続再生（将来用）=====
                          // ShopListCard(
                          //   icon: Icons.play_circle_outline,
                          //   title:
                          //       AppLocalizations.of(context)!.shopTitleAutoplay,
                          //   description:
                          //       AppLocalizations.of(context)!.shopDescAutoplay,
                          //   enabled: false,
                          //   purchased: false,
                          //   iconColor: const Color(0xFFE67E22),
                          //   priceLabel: "0",
                          //   minHeight: 90,
                          // ),

                          const SizedBox(height: 50),

                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                logger.i("-----restore tap-----");
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => isProcessing = true);

                                try {
                                  final iap = context.read<IapProvider>();

                                  final beforeRemove =
                                      iap.isPurchased(IapProducts.removeAds.id);
                                  final beforeLimit = iap
                                      .isPurchased(IapProducts.limitUpgrade.id);

                                  _suppressIapSnack = true;

                                  // ✅ restore中に purchaseStream が反映するまで待つ実装になっている前提
                                  await iap.service.restore();

                                  final afterRemove =
                                      iap.isPurchased(IapProducts.removeAds.id);
                                  final afterLimit = iap
                                      .isPurchased(IapProducts.limitUpgrade.id);

                                  _suppressIapSnack = false;

                                  final restoredNow =
                                      (!beforeRemove && afterRemove) ||
                                          (!beforeLimit && afterLimit);

                                  final alreadyOwned =
                                      afterRemove || afterLimit;

                                  logger.i("購入を復元タップ後のIAP状態："
                                      "beforeRemove1^$beforeRemove "
                                      "beforeLimit=$beforeLimit "
                                      "afterRemove=$afterRemove "
                                      "afterLimit=$afterLimit "
                                      "restoredNow=$restoredNow alreadyOwned=$alreadyOwned");

                                  // ✅ SnackBarはこの1回だけ
                                  final String msg;
                                  if (restoredNow) {
                                    msg = AppLocalizations.of(context)!
                                        .shopRestoreDone;
                                  } else if (alreadyOwned) {
                                    msg = AppLocalizations.of(context)!
                                        .shopRestoreAlready;
                                  } else {
                                    msg = AppLocalizations.of(context)!
                                        .shopRestoreNothing;
                                  }

                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                      ),
                                    );
                                } finally {
                                  _suppressIapSnack = false;
                                  if (mounted) {
                                    setState(() => isProcessing = false);
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.restore,
                                size: 18,
                                color: Colors.white70,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.shopRestore,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ← 戻る（通常表示）
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ===== 処理中オーバーレイ =====
          if (isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class ShopListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final bool purchased;
  final Color iconColor;
  final VoidCallback? onBuy;
  final String priceLabel;
  final double minHeight;

  const ShopListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.purchased,
    required this.iconColor,
    this.onBuy,
    required this.priceLabel,
    this.minHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 44,
                    color: iconColor,
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 5),

                  // 右端：購入済み（ボタンの代わり）
                  if (purchased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.shopPurchased,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )

                  // 未購入 → 「購入する」
                  else if (enabled)
                    SizedBox(
                      height: 60,
                      width: 85,
                      child: ElevatedButton(
                        onPressed: onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.shopBuy(priceLabel),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Coming soon
        if (!enabled && !purchased)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(right: 25),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    "assets/images/coming_soon.png",
                    width: 80,
                    opacity: const AlwaysStoppedAnimation(0.8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
