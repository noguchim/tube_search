import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/watch_history_item.dart';
import '../providers/iap_provider.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/watch_history_service.dart';
import '../utils/handle_favorite_tap.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/ui_spacing.dart';
import '../widgets/ad_banner.dart';
import '../widgets/favorite_button_overlay.dart';
import '../widgets/play_button_overlay.dart';
import '../widgets/top_bar_back.dart';

enum _HistoryMenuAction {
  favorite,
  delete,
}

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopBar = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // -----------------------------
  // スクロールでTopBar制御
  // -----------------------------
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final d = _scrollController.position.userScrollDirection;

    if (d == ScrollDirection.reverse && _showTopBar) {
      setState(() => _showTopBar = false);
    } else if (d == ScrollDirection.forward && !_showTopBar) {
      setState(() => _showTopBar = true);
    }
  }

  Map<String, List<WatchHistoryItem>> _group(List<WatchHistoryItem> items) {
    final map = <String, List<WatchHistoryItem>>{};

    for (var item in items) {
      final key = DateFormat('yyyy/MM/dd').format(item.watchedAt);
      map.putIfAbsent(key, () => []);
      map[key]!.add(item);
    }

    return map;
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool adsRemoved =
        context.watch<IapProvider>().isPurchased(IapProducts.removeAds.id);

    final double safeTop = MediaQuery.of(context).padding.top;
    final items = context.watch<WatchHistoryService>().items;
    final grouped = _group(items);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =============================
          // 背面（スクロール or 空状態）
          // =============================
          items.isEmpty
              ? const Center(
                  child: Text(
                    "視聴履歴がありません",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<WatchHistoryService>().load();
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // 👇 TopBarスペーサ（絶対必要）
                      SliverToBoxAdapter(
                        child: SizedBox(height: 55 + safeTop),
                      ),

                      // 👇 履歴リスト
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final date = dates[index];
                            final items = grouped[date]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 日付
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                ...items.map(_item),
                              ],
                            );
                          },
                          childCount: dates.length,
                        ),
                      ),

                      // 👇 下余白
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: UISpacing.bottomSpacer(
                            context,
                            hasFab: false,
                            hasAd: !adsRemoved,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

          // =============================
          // 🧭 TopBar（最前面）
          // =============================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _showTopBar ? Offset.zero : const Offset(0, -1.1),
              child: TopBarBack(
                title: "視聴履歴",
                showSort: false,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // =============================
          // Ad
          // =============================
          if (!adsRemoved)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AdBanner(isMain: false),
            ),
        ],
      ),
    );
  }

  // -----------------------------
  // アイテム
  // -----------------------------
  Widget _item(WatchHistoryItem item) {
    final video = item.video;
    bool isPushing = false;
    final fav = context.watch<FavoritesService>();
    final isFav = fav.isFavoriteSync(video.id);

    return InkWell(
      onTap: () async {
        if (isPushing) return;
        isPushing = true;
        try {
          final id = video.id;
          if (id.isEmpty) return;

          await openYouTubeInInAppBrowser(context, videoId: id);
        } finally {
          isPushing = false;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // サムネ
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    width: 160,
                    height: 90,
                    fit: BoxFit.cover,

                    // 🔥 ここ追加
                    errorBuilder: (_, __, ___) {
                      return Image.asset(
                        'assets/images/no_image.png',
                        width: 160,
                        height: 90,
                        fit: BoxFit.cover,
                      );
                    },
                  ),

                  // ▶ 再生ボタン
                  const Positioned.fill(
                    child: PlayButtonOverlay(
                      sizeOverride: 30,
                    ),
                  ),

                  // ❤️ お気に入り
                  Positioned(
                    top: -4,
                    right: -2,
                    child: FavoriteButtonOverlay(
                      isFavorite: isFav,
                      showBackground: true,
                      scale: 0.9,
                      onTap: () => handleFavoriteTap(context, video: video),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 10),

                  // 👇 シンプルにする
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
