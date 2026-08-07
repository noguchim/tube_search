import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../providers/region_provider.dart';
import '../services/favorites_service.dart';
import '../services/iap_products.dart';
import '../services/limit_service.dart';
import '../services/watch_history_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/admob_config.dart';
import '../utils/favorite_delete_helper.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/request_review.dart';
import '../utils/ui_spacing.dart';
import '../widgets/app_dialog.dart';
import '../widgets/live_badge.dart';
import '../widgets/play_button_overlay.dart';
import '../widgets/thumbnail_playback_progress.dart';
import '../widgets/top_bar.dart';

enum _FavMenuAction { lock, delete }

class FavoritesScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;
  final ValueChanged<List<YouTubeVideo>>? onVideosChanged;

  const FavoritesScreen({
    super.key,
    this.onScrollChanged,
    this.onVideosChanged,
  });

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver {
  bool _isPushing = false;
  final ScrollController _scrollController = ScrollController();
  String _lastPublishedVideoSignature = '';

  void scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初回ロード
    final favorites = context.read<FavoritesService>();
    Future.microtask(() async {
      await favorites.loadFavorites();
      if (!mounted) return;
      await refreshMetadata();
    });
  }

  Future<void> refreshMetadata() async {
    if (!mounted) return;

    await context.read<FavoritesService>().refreshIncompleteMetadata(
      context.read<YouTubeApiService>(),
      regionCode: context.read<RegionProvider>().regionCode,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await maybeAskForReview();
      await refreshMetadata();
    }
  }

  // -------------------------------------------------------------
  // 空UI
  // -------------------------------------------------------------
  Widget _buildEmptyFavoritesUI() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),
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
  // YouTube再生
  // -------------------------------------------------------------
  Future<void> _pushPlayer(BuildContext context, YouTubeVideo video) async {
    if (_isPushing) return;
    _isPushing = true;

    try {
      if (video.id.isEmpty) return;

      await openYouTubeInInAppBrowser(
        context,
        videoId: video.id,
        durationSeconds: video.durationSeconds,
      );
    } finally {
      _isPushing = false;
    }
  }

  // -------------------------------------------------------------
  // 件数ヘッダー
  // -------------------------------------------------------------
  SliverToBoxAdapter _buildCountHeader(
    BuildContext context,
    int current,
    int limit,
  ) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFE4E8EC),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.favoritesCountMessage(current, limit),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // タイル
  // -------------------------------------------------------------
  Widget _buildFavoriteTile(BuildContext context, YouTubeVideo video) {
    final favService = context.read<FavoritesService>();
    final isLocked = video.locked == true;

    final savedAt = video.savedAt != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).format(video.savedAt!)
        : "";

    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サムネ
          InkWell(
            onTap: () {
              context.read<WatchHistoryService>().add(video);
              _pushPlayer(context, video);
            },
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    width: 165,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Image.asset(
                        'assets/images/no_image.png',
                        width: 165,
                        height: 100,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  const Positioned.fill(
                    child: PlayButtonOverlay(sizeOverride: 30),
                  ),
                  if (video.isLive)
                    const Positioned(
                      left: 5,
                      bottom: 9,
                      child: IgnorePointer(
                        child: LiveBadge(
                          fontSize: 11.5,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          backgroundColor: Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ThumbnailPlaybackProgress(
                    videoId: video.id,
                    durationSeconds: video.durationSeconds,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // テキスト
          Expanded(
            child: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        child: isLocked
                            ? Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(99),
                                    onTap: () async {
                                      HapticFeedback.lightImpact();

                                      await showUnlockDialog(
                                        context,
                                        onConfirm: () async {
                                          await favService.toggleLock(video.id);
                                        },
                                      );
                                    },
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 28,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              )
                            : PopupMenuButton<_FavMenuAction>(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 24,
                                icon: const Icon(Icons.more_vert),
                                onSelected: (action) async {
                                  HapticFeedback.lightImpact();

                                  switch (action) {
                                    case _FavMenuAction.lock:
                                      await favService.toggleLock(video.id);
                                      break;

                                    case _FavMenuAction.delete:
                                      await FavoriteDeleteHelper.confirmOrDelete(
                                        context,
                                        video,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _FavMenuAction.lock,
                                    child: ListTile(
                                      leading: const Icon(Icons.lock_outline),
                                      title: Text(t.favoriteLock),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _FavMenuAction.delete,
                                    child: ListTile(
                                      leading: const Icon(Icons.delete_outline),
                                      title: Text(t.favoriteDelete),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    video.channelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      // fontWeight: FontWeight.w700,
                      // color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    savedAt,
                    style: const TextStyle(
                      fontSize: 14,
                      // color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // リスト表示
  // -------------------------------------------------------------
  Widget _buildFavoritesContent(List<YouTubeVideo> list) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    if (!isLandscape) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFavoriteTile(context, list[i]),
            );
          }, childCount: list.length),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, i) {
          return _buildFavoriteTile(context, list[i]);
        }, childCount: list.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 105,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fav = context.watch<FavoritesService>();
    final list = fav.items;
    final signature = list
        .map(
          (video) =>
              '${video.id}:${video.durationSeconds}:${video.isLive}:'
              '${video.liveBroadcastContent}',
        )
        .join('|');
    if (signature != _lastPublishedVideoSignature) {
      _lastPublishedVideoSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVideosChanged?.call(List<YouTubeVideo>.unmodifiable(list));
      });
    }

    final iap = context.watch<IapProvider>();
    final favoritesLimit = LimitService.favoritesLimit(iap);
    final adsRemoved = iap.isPurchased(IapProducts.removeAds.id);
    final shouldShowAds = AdMobConfig.shouldShowAds(adsRemoved: adsRemoved);

    final currentCount = list.length;

    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final double topBarOffset = TopBarSpec.total(safeTop);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topBarOffset)),
          if (currentCount > 0)
            _buildCountHeader(context, currentCount, favoritesLimit),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: _buildEmptyFavoritesUI(),
              ),
            )
          else
            _buildFavoritesContent(list),
          SliverToBoxAdapter(
            child: SizedBox(
              height: UISpacing.bottomSpacer(
                context,
                hasFab: true,
                hasAd: shouldShowAds,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Unlock dialog
  // -------------------------------------------------------------
  Future<void> showUnlockDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) {
        return AppDialog(
          title: t.favoriteUnlockTitle,
          message: t.favoriteUnlockMessage,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.favoriteUnlockCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(t.favoriteUnlockConfirm),
            ),
          ],
        );
      },
    );
  }
}
