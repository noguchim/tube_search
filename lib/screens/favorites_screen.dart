import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../utils/favorite_delete_helper.dart';
import '../utils/open_in_custom_tabs.dart';
import '../utils/request_review.dart';
import '../utils/ui_spacing.dart';
import '../widgets/app_dialog.dart';
import '../widgets/play_button_overlay.dart';
import '../widgets/top_bar.dart';

enum _FavMenuAction {
  lock,
  delete,
}

class FavoritesScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const FavoritesScreen({super.key, this.onScrollChanged});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver {
  bool _isPushing = false;
  final ScrollController _scrollController = ScrollController();

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
    Future.microtask(() {
      context.read<FavoritesService>().loadFavorites();
    });
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
  Future<void> _pushPlayerById(BuildContext context, String id) async {
    if (_isPushing) return;
    _isPushing = true;

    try {
      if (id.isEmpty) return;

      await openYouTubeInInAppBrowser(
        context,
        videoId: id,
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
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFE4E8EC),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)!
                  .favoritesCountMessage(current, limit),
              style: TextStyle(
                fontSize: 13,
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
  Widget _buildFavoriteTile(
    BuildContext context,
    YouTubeVideo video,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final favService = context.read<FavoritesService>();
    final isLocked = video.locked == true;

    final savedAt = video.savedAt != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(video.savedAt!)
        : "";

    final t = AppLocalizations.of(context)!;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // サムネ
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _pushPlayerById(context, video.id),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Ink.image(
                      image: NetworkImage(video.thumbnailUrl),
                      width: 88,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                    const PlayButtonOverlay(
                      sizeOverride: 28,
                      subtle: true,
                    ),
                  ],
                ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          video.channelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          savedAt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // 操作
            isLocked
                ? InkWell(
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
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 30,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  )
                : PopupMenuButton<_FavMenuAction>(
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
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // リスト表示
  // -------------------------------------------------------------
  Widget _buildFavoritesContent(List<YouTubeVideo> list) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isTablet = media.size.shortestSide >= 600;

    if (!isLandscape) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildFavoriteTile(context, list[i]),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 105,
      ),
      itemBuilder: (context, i) => _buildFavoriteTile(context, list[i]),
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

    final iap = context.watch<IapProvider>();
    final favoritesLimit = LimitService.favoritesLimit(iap);

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
          SliverToBoxAdapter(
            child: list.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: _buildEmptyFavoritesUI(),
                  )
                : _buildFavoritesContent(list),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: UISpacing.bottomSpacer(
                context,
                hasFab: true,
                hasAd: true,
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
      builder: (_) {
        return AppDialog(
          title: t.favoriteUnlockTitle,
          message: t.favoriteUnlockMessage,
          style: AppDialogStyle.info,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.favoriteUnlockCancel),
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
