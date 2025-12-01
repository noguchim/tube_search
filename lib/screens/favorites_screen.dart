import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/video_player_screen.dart';
import '../services/favorites_service.dart';
import '../widgets/custom_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _list = [];
  static const String _prefSkipDeleteConfirm = "skip_delete_confirm";

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  // -------------------------------------------------------------
  // 初期ロード
  // -------------------------------------------------------------
  Future<void> _initLoad() async {
    final fav = context.read<FavoritesService>();
    await fav.loadFavorites();
    final data = await fav.getFavorites();

    if (mounted) {
      setState(() {
        _list = data;
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------------------
  // 外部から reload 呼ばれたとき
  // -------------------------------------------------------------
  Future<void> reload() async {
    final fav = context.read<FavoritesService>();
    await fav.loadFavorites();
    final data = await fav.getFavorites();

    if (mounted) {
      setState(() {
        _list = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> video) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          // YouTube 風：シンプル・クリーン
          title: const Text(
            "お気に入りから削除しますか？",
            style: TextStyle(fontSize: 15),
          ),

          content: Text(
            "「${video["title"]}」をお気に入りから削除します。",
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),

          actions: [
            TextButton(
              child: const Text(
                "キャンセル",
                style: TextStyle(fontSize: 14),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text(
                "削除",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final fav = context.read<FavoritesService>();
                await fav.toggle(video["id"], video);

                if (mounted) {
                  Navigator.pop(context); // ダイアログを閉じる
                  await reload(); // リスト更新
                }
              },
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 削除処理（確認あり）
  // -------------------------------------------------------------
  Future<void> _tryDelete(Map<String, dynamic> video) async {
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_prefSkipDeleteConfirm) ?? false;

    // ★ 確認なしモードなら即削除
    if (skip) {
      final fav = context.read<FavoritesService>();
      await fav.toggle(video["id"], video);
      await reload();
      return;
    }

    // ★ 通常 → ダイアログ表示
    await _showDeleteDialog(video);
  }

  Widget _buildEmptyFavoritesUI() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "お気に入りがありません",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF646A70),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "🖤タップでお気に入りに追加！",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF646A70),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // ★ ポップなミニ動画カード（少し小さめ）
            AnimatedScale(
              scale: 1.00,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    // 赤背景サムネ
                    Container(
                      width: double.infinity,
                      height: 100,
                      color: const Color(0xFFB5B9BE),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // 下の説明エリア
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent.shade100.withOpacity(0.12),
                            Colors.pinkAccent.shade100.withOpacity(0.04),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.85, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutBack,
                            builder: (context, scale, _) {
                              return Transform.scale(
                                scale: scale,
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Colors.pinkAccent,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_left_rounded,
                            color: Colors.pinkAccent.shade100,
                            size: 26,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              "ここをタップ！",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF646A70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: _list.length,
        itemBuilder: (context, i) {
          final video = _list[i];
          final savedAtRaw = video["savedAt"] ?? "";
          final savedAt = (savedAtRaw.isNotEmpty)
              ? DateFormat("yyyy-MM-dd").format(DateTime.parse(savedAtRaw))
              : "";

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(video: video),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      video["thumbnailUrl"] ?? "",
                      width: 95,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[300]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          video["title"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video["channelTitle"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$savedAt 登録",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async => _tryDelete(video),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    context.watch<FavoritesService>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: CustomScrollView(
        slivers: [
          // ===============================================================
          // 🪩 共通ガラスAppBar（設定画面と同じレイアウト）
          // ===============================================================
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 82,
            flexibleSpace: const CustomGlassAppBar(
              title: 'お気に入り',
              showRefreshButton: false,
            ),
          ),

          // ===============================================================
          // 🧊 本体（空表示 or リスト表示）
          // ===============================================================
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _list.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: Center(
                          child: _buildEmptyFavoritesUI(),
                        ),
                      )
                    : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }
}
