import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/iap_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../widgets/custom_glass_app_bar.dart';

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "お気に入りから削除しますか？",
            style: TextStyle(fontSize: 15, color: onSurface),
          ),
          content: Text(
            "「${video["title"]}」をお気に入りから削除します。",
            style: TextStyle(fontSize: 14, height: 1.5, color: onSurface),
          ),
          actions: [
            TextButton(
              child: Text(
                "キャンセル",
                style: TextStyle(fontSize: 14, color: onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text(
                "削除",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final fav = context.read<FavoritesService>();
                await fav.toggle(video["id"], video);

                if (mounted) {
                  Navigator.pop(context);
                  await reload();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _tryDelete(Map<String, dynamic> video) async {
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_prefSkipDeleteConfirm) ?? false;

    if (skip) {
      final fav = context.read<FavoritesService>();
      await fav.toggle(video["id"], video);
      await reload();
      return;
    }

    await _showDeleteDialog(video);
  }

  // -------------------------------------------------------------
  // 空UI（Light / Dark 対応版に全面改修）
  // -------------------------------------------------------------
  Widget _buildEmptyFavoritesUI() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final cardColor =
        theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 30), // AppBar 下の余白調整（必要に応じて調整可）

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "お気に入りがありません",
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "アイコンタップでお気に入りに追加！",
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // ★ ダークテーマ対応ミニカード
                AnimatedScale(
                  scale: 1.00,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 100,
                          color: isDark ? Colors.grey[800] : const Color(0xFFB5B9BE),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                Colors.white.withValues(alpha: 0.05),
                                Colors.white.withValues(alpha: 0.02),
                              ]
                                  : [
                                Colors.pinkAccent.shade100.withValues(alpha: 0.12),
                                Colors.pinkAccent.shade100.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_border_rounded,
                                  color: Colors.pinkAccent, size: 22),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_left_rounded,
                                  color: Colors.pinkAccent, size: 26),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "ここをタップ！",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 90), // 下側の余白も自然に確保
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LIST（ダークテーマ対応）
  // -------------------------------------------------------------
  Widget _buildFavoritesList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

          final cardColor = theme.cardTheme.color!;
          final onSurface = theme.colorScheme.onSurface;

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
                color: cardColor,
                borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
                    ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
                    : BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      video["thumbnailUrl"] ?? "",
                      width: 95,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video["channelTitle"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$savedAt 登録",
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: () async => _tryDelete(video),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
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
    final theme = Theme.of(context);
    final iap = context.watch<IapProvider>();
    final favoritesLimit = LimitService.favoritesLimit(iap);
    final currentCount = _list.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: false,
            snap: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 70,
            flexibleSpace: const CustomGlassAppBar(
              title: 'お気に入り',
            ),
          ),

          // 🔹 0件のときは表示しない
          if (!_isLoading && currentCount > 0)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFE4E8EC),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "お気に入り登録数：$currentCount / $favoritesLimit 件",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
                : _list.isEmpty
                ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: _buildEmptyFavoritesUI(),
            )
                : _buildFavoritesList(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}
