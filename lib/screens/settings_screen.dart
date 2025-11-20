import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart'; // ✅ 共通ヘッダをインポート

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),

      body: CustomScrollView(
        slivers: [
          /// 🪩 共通ガラスAppBar（更新ボタンなし）
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 82, // ✅ 他画面と高さ統一
            flexibleSpace: const CustomGlassAppBar(
              title: '設定',
              showRefreshButton: false,
            ),
          ),

          /// ⚙️ 本体
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                '⚙️ 設定画面（開発中）',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
