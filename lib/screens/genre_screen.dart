// lib/screens/genre_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/base_genre_models.dart';
import '../data/genre_provider.dart';
import '../providers/region_provider.dart';
import '../utils/app_logger.dart';
import '../utils/ui_spacing.dart';
import '../widgets/top_bar.dart';
import 'genre_videos_screen.dart';

class GenreScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const GenreScreen({super.key, this.onScrollChanged});

  @override
  State<GenreScreen> createState() => GenreScreenState();
}

class GenreScreenState extends State<GenreScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = false;
  bool _didInitialJump = false;
  double _lastOffset = 0;

  @override
  bool get wantKeepAlive => true;

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
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialJump) return;
    _didInitialJump = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // 🔥 スクロール方向通知
  // ----------------------------------------------------
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    // 🔥 トップ付近は常に表示（最重要）
    if (offset <= 10) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        widget.onScrollChanged?.call(false);
      }
      _lastOffset = offset;
      return;
    }

    final delta = offset - _lastOffset;

    // 🔽 下スクロール（ある程度動いた時だけ）
    if (delta > 5) {
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        widget.onScrollChanged?.call(true);
      }
    }

    // 🔼 上スクロール
    else if (delta < -5) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        widget.onScrollChanged?.call(false);
      }
    }

    _lastOffset = offset;
  }

  // ----------------------------------------------------
  // 🔥 グループセクション
  // ----------------------------------------------------
  Widget _buildGroupSection(GenreGroup group) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool useDynamicLayout = !isTablet && !isLandscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Icon(group.icon, color: group.color, size: 22),
              const SizedBox(width: 8),
              Text(
                group.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final itemWidth = (maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 6,
                children: group.items.map((cat) {
                  int weightedLength(String text) {
                    int count = 0;

                    for (final c in text.runes) {
                      // 全角っぽい範囲
                      if (c > 0x3000) {
                        count += 2;
                      } else {
                        count += 1;
                      }
                    }
                    return count;
                  }

                  final isLong = weightedLength(cat.name) >= 12;

                  final double width = useDynamicLayout
                      ? (isLong ? maxWidth : itemWidth)
                      : itemWidth;

                  return SizedBox(
                    width: width,
                    child: _buildCategoryTile(
                      context,
                      group,
                      cat,
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    GenreGroup group,
    GenreCategory cat,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    final Color accentColor = cat.color ?? group.color;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.04),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final categoryId = cat.id.toString();
            final categoryTitle = cat.name;
            final keyword = cat.query;

            logger.i(
                "[_buildCategoryTile to GenreVideosScreen]categoryId=$categoryId "
                "categoryTitle=$categoryTitle keyword=$keyword searchMode=or");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenreVideosScreen(
                  categoryId: categoryId,
                  categoryTitle: categoryTitle,
                  keyword: keyword,
                  searchMode: "or",
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Container(
                    width: 12,
                    color: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12 + 14, 14, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 🧩 本体
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final region = context.watch<RegionProvider>().regionCode;
    final groups = getGenreGroupsForRegion(region);
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final extraTopGap = isTablet ? 12.0 : 8.0;
    final double topBarOffset = TopBarSpec.total(safeTop) + extraTopGap;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: CustomScrollView(
          key: const PageStorageKey("genre_scroll"),
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topBarOffset)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) => _buildGroupSection(groups[idx]),
                childCount: groups.length,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: UISpacing.bottomSpacer(
                  context,
                  hasFab: false,
                  hasAd: true,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
