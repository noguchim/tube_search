import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // リスト
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
              children: const [
                ShopListCard(
                  icon: Icons.ads_click,
                  title: "広告削除",
                  description: "広告を非表示にします",
                  enabled: true,
                ),
                SizedBox(height: 16),
                ShopListCard(
                  icon: Icons.play_circle_outline,
                  title: "連続再生",
                  description: "動画を自動で連続再生",
                  enabled: false,
                ),
              ],
            ),
            // 戻る
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black.withOpacity(0.35), // 半透明背景
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10), // ← タップしやすさの肝
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
    );
  }
}

class ShopListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;

  const ShopListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ===== ベースカード =====
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
                  size: 36,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black26,
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  OutlinedButton(
                    onPressed: () {
                      // TODO: 購入処理
                    },
                    child: const Text("購入する"),
                  ),
              ],
            ),
          ),
        ),

        // ===== Coming soon オーバーレイ =====
        if (!enabled)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(right: 12), // ← ここで余白調整
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    "assets/images/coming_soon.png",
                    width: 90,
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

