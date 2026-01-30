import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../services/favorites_service.dart';
import '../services/limit_service.dart';
import '../utils/favorite_delete_helper.dart';
import '../utils/open_in_custom_tabs.dart';
import '../widgets/app_dialog.dart';

enum _FavMenuAction {
  lock,
  delete,
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _list = [];
  bool _isPushing = false;

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

  // -------------------------------------------------------------
  // 空UI（Light / Dark 対応版に全面改修）
  // -------------------------------------------------------------
  Widget _buildEmptyFavoritesUI() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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

  Future<void> _pushPlayerById(BuildContext context, String id) async {
    if (_isPushing) return;
    _isPushing = true;
    try {
      final videoId = id.trim();
      if (videoId.isEmpty) return;

      await openYouTubeInInAppBrowser(context, videoId: videoId);
    } finally {
      _isPushing = false;
    }
  }

  SliverToBoxAdapter _buildCountHeader(
    BuildContext context,
    int current,
    int limit,
  ) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFE4E8EC),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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

  Widget _buildFavoriteTile(
    BuildContext context,
    Map<String, dynamic> video,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final favService = context.read<FavoritesService>();

    final bool isLocked = video["locked"] == true;

    final savedAtRaw = video["savedAt"] ?? "";
    final savedAt = savedAtRaw.isNotEmpty
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(DateTime.parse(savedAtRaw))
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
            // =========================
            // 🎬 サムネ（再生はここだけ）
            // =========================
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final id = (video["videoId"] ??
                            video["id"] ??
                            video["youtubeId"] ??
                            "")
                        .toString();
                    _pushPlayerById(context, id);
                  },
                  splashColor: Colors.white.withValues(alpha: 0.22),
                  highlightColor: Colors.white.withValues(alpha: 0.10),
                  child: Ink.image(
                    image: NetworkImage(video["thumbnailUrl"] ?? ""),
                    width: 88,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // =========================
            // 📝 テキスト（操作不可）
            // =========================
            Expanded(
              child: IgnorePointer(
                ignoring: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // ← 全体は左基準
                  children: [
                    // =========================
                    // 📝 タイトル（左寄せ）
                    // =========================
                    Text(
                      video["title"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),

                    // const SizedBox(height: 4),

                    // =========================
                    // 📄 サブ情報（右寄せブロック）
                    // =========================
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          Text(
                            savedAt,
                            textAlign: TextAlign.right,
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
            ),

            const SizedBox(width: 4),

            // =========================
            // 🔒 / ⋮ 操作エリア
            // =========================
            isLocked
                ? InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () async {
                      HapticFeedback.lightImpact();

                      await showUnlockDialog(
                        context,
                        onConfirm: () async {
                          await favService.toggleLock(video["id"]);
                          await reload();
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 30,
                        color: Colors.amber.shade700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  )
                : PopupMenuButton<_FavMenuAction>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 26,
                    ),
                    onSelected: (action) async {
                      HapticFeedback.lightImpact();

                      switch (action) {
                        case _FavMenuAction.lock:
                          await favService.toggleLock(video["id"]);
                          await reload();
                          break;

                        case _FavMenuAction.delete:
                          await FavoriteDeleteHelper.confirmOrDelete(
                            context,
                            video,
                          );
                          await reload();
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

  Widget _buildFavoritesContent() {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isTablet = media.size.shortestSide >= 600;

    if (!isLandscape) {
      // 縦：今まで通り List
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildFavoriteTile(context, _list[i]),
      );
    }

    // 横：Smallデザインのまま Grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 105, // ← Small感を固定
      ),
      itemBuilder: (context, i) => _buildFavoriteTile(context, _list[i]),
    );
  }

  Future<void> showUnlockDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppDialog(
          title: t.favoriteUnlockTitle,
          message: t.favoriteUnlockMessage,
          style: AppDialogStyle.info,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t.favoriteUnlockCancel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
          if (!_isLoading && currentCount > 0)
            _buildCountHeader(context, currentCount, favoritesLimit),
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
                    : _buildFavoritesContent(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 70)),
        ],
      ),
    );
  }
}
