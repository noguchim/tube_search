import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ① ベース背景（ほぼフラット）
          Container(
            color: const Color(0xFF0E1A2B),
          ),

          // ② 上部ライト（ここが肝）
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(70, 120, 160, 220), // 青白い光
                    Color.fromARGB(0, 120, 160, 220),
                  ]
              ),
            ),
          ),

          // ③ 中身
          SafeArea(
            child: Stack(
              children: [
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

                // 戻るボタン
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.black.withOpacity(0.35),
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
                  size: 56,
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
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 購入処理
                      },
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

        // ===== Coming soon オーバーレイ =====
        if (!enabled)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(right: 25), // ← ここで余白調整
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

