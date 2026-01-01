import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/iap_provider.dart';
import '../services/iap_products.dart';
import '../utils/app_logger.dart';

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

  @override
  void initState() {
    super.initState();

    _provider = context.read<IapProvider>();

    _lastRemoveAds = _provider!.isPurchased(IapProducts.removeAds.id);
    _lastLimit = _provider!.isPurchased(IapProducts.limitUpgrade.id);

    _provider!.addListener(_onIapChanged);
  }

  void _onIapChanged() {
    final provider = context.read<IapProvider>();

    final remove = provider.isPurchased(IapProducts.removeAds.id);
    final limit = provider.isPurchased(IapProducts.limitUpgrade.id);

    if (!_lastRemoveAds && remove) {
      _showSnack(IapProducts.removeAds.purchaseMessage);
    }

    if (!_lastLimit && limit) {
      _showSnack(IapProducts.limitUpgrade.purchaseMessage);
    }

    _lastRemoveAds = remove;
    _lastLimit = limit;
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
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
                  children: [
                    // ===== 広告削除 =====
                    ShopListCard(
                      icon: Icons.ads_click,
                      title: "広告削除",
                      description: "広告を非表示にします",
                      enabled: !removeAdsPurchased,
                      purchased: removeAdsPurchased,
                      iconColor: Theme.of(context).colorScheme.primary,
                      onBuy: removeAdsPurchased
                          ? null
                          : () async {
                              logger.i('[UI] Buy tapped');

                              setState(() => isProcessing = true);

                              try {
                                // ① await の前で context 依存を完了しておく
                                final messenger = ScaffoldMessenger.of(context);
                                final iap = context.read<IapProvider>().service;

                                // ② async
                                final product = await iap
                                    .loadProduct(IapProducts.removeAds.id);

                                if (product == null) {
                                  // ③ context をもう直接使わない（messenger でOK）
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('商品情報を取得できませんでした'),
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
                      title: "上限拡張",
                      description: "人気一覧表示とお気に入り登録の上限が5倍に",
                      enabled: !limitUpgradePurchased,
                      purchased: limitUpgradePurchased,
                      iconColor: const Color(0xFF9B59B6),
                      onBuy: limitUpgradePurchased
                          ? null
                          : () async {
                              logger.i('[UI] Buy tapped (limit_upgrade)');
                              setState(() => isProcessing = true);

                              try {
                                // ① await の前で context 依存を解決
                                final messenger = ScaffoldMessenger.of(context);
                                final iap = context.read<IapProvider>().service;

                                // ② async
                                final product = await iap
                                    .loadProduct(IapProducts.limitUpgrade.id);

                                if (product == null) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('商品情報を取得できませんでした'),
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
                    const ShopListCard(
                      icon: Icons.play_circle_outline,
                      title: "連続再生",
                      description: "動画を自動で連続再生",
                      enabled: false,
                      purchased: false,
                      iconColor: Color(0xFFE67E22),
                    ),

                    // ===== Restore =====
                    const SizedBox(height: 24),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // ① 先に Messenger を確保
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isProcessing = true);

                          try {
                            final iap = context.read<IapProvider>().service;
                            await iap.restore();
                          } finally {
                            if (mounted) {
                              setState(() => isProcessing = false);
                            }
                          }

                          // ② async のあとでも安全
                          messenger.showSnackBar(
                            const SnackBar(content: Text('購入を復元しました')),
                          );
                        },
                        icon: const Icon(
                          Icons.restore,
                          size: 18,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          '購入を復元',
                          style: TextStyle(
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
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),

                // 戻るボタン
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

  const ShopListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.purchased,
    required this.iconColor,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 56,
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          "購入済み",
                          style: TextStyle(
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
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6EA5),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("購入する"),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Coming soon（← purchased の場合は絶対出さない）
        if (!enabled && !purchased)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(right: 25),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    "assets/images/coming_soon.png",
                    width: 70,
                    opacity: const AlwaysStoppedAnimation(0.9),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
