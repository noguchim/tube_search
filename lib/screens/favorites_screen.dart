import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/screens/video_player_screen.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../utils/favorite_delete_helper.dart';
import '../widgets/light_flat_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _list = [];

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

  Future<void> _tryDelete(Map<String, dynamic> video) async {
    await FavoriteDeleteHelper.confirmOrDelete(context, video);
    await reload(); // ← 解除後の最新一覧を再取得
  }

  // -------------------------------------------------------------
  // 空UI（Light / Dark 対応版に全面改修）
  // -------------------------------------------------------------
  Widget _buildEmptyFavoritesUI() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            // ✅ ここが重要：最低でも画面の高さを確保 → 縦では中央寄せが維持できる
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ✅ ここは Expanded じゃなく Spacer で柔軟にする
                  const Spacer(),

                  Text(
                    AppLocalizations.of(context)!.favoritesTitle,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.favoritesEmptyHint,
                    style: TextStyle(
                      fontSize: 15,
                      color: onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 空状態カード（サイズは維持しつつ）
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
                            color: isDark
                                ? Colors.grey[800]
                                : const Color(0xFFB5B9BE),
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
                                        Colors.pinkAccent.shade100
                                            .withValues(alpha: 0.12),
                                        Colors.pinkAccent.shade100
                                            .withValues(alpha: 0.04),
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
                                    AppLocalizations.of(context)!
                                        .favoritesTapHere,
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

                  const Spacer(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        );
      },
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
              ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
                  .format(DateTime.parse(savedAtRaw))
              : "";

          final cardColor = theme.colorScheme.surface;
          final onSurface = theme.colorScheme.onSurface;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
                    ? (theme.cardTheme.shape as RoundedRectangleBorder)
                        .borderRadius
                    : BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              elevation: 0, // 影は下のBoxShadowで付ける
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
                      ? (theme.cardTheme.shape as RoundedRectangleBorder)
                          .borderRadius
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
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // ✅ サムネ（波紋出すなら Ink.image がベスト）
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                  video: video, isRepeat: false),
                            ),
                          ),
                          splashColor: Colors.white.withValues(alpha: 0.22),
                          highlightColor: Colors.white.withValues(alpha: 0.08),
                          child: Ink.image(
                            image: NetworkImage(video["thumbnailUrl"] ?? ""),
                            fit: BoxFit.cover,
                            width: 95,
                            height: 60,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: IgnorePointer(
                          ignoring: true,
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
                                "$savedAt ${AppLocalizations.of(context)!.favoritesRegisteredSuffix}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async => _tryDelete(video),
                          borderRadius: BorderRadius.circular(99),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          SliverAppBar(
            floating: false,
            snap: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 65,
            flexibleSpace: LightFlatAppBar(
              title: AppLocalizations.of(context)!.favoritesTitle,
            ),
          ),

          // 🔹 0件のときは表示しない
          if (!_isLoading && currentCount > 0)
            SliverToBoxAdapter(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFE4E8EC),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.favoritesCountMessage(
                        currentCount,
                        favoritesLimit,
                      ),
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
