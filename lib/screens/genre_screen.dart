// lib/screens/genre_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/base_genre_models.dart';
import '../data/genre_groups_ja.dart';
import '../data/genre_provider.dart';
import '../data/search_history_item.dart';
import '../data/trending_keyword.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/ui_spacing.dart';
import 'genre_videos_screen.dart';

class GenreScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const GenreScreen({super.key, this.onScrollChanged});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String _lastRegion = "JP";
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _networkError = false;

  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoadingSuggest = false;
  bool _isSearchingFromSuggest = false;

  bool _isScrollingDown = false;

  late AnimationController _tapAnim;
  late Animation<double> _scaleAnim;

  bool _didInitialJump = false;

  List<TrendingKeyword> _trending = [];
  bool _trendingLoaded = false;
  bool _showAllTrending = false;
  String _trendingTimestamp = "";

  // ============================================================
  // 🔎 Search History
  // ============================================================
  static const String _historyKey = "search_history_v1";
  static const int _historyMax = 12;
  List<SearchHistoryItem> _searchHistory = [];
  bool _isLoadingHistory = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _tapAnim, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      // ✅ フォーカス変化でサジェスト/履歴の表示が切り替わるので再描画
      if (mounted) setState(() {});
      if (_focusNode.hasFocus) {
        Feedback.forTap(context);
      }
    });

    // ✅ 起動時に履歴ロード
    _loadSearchHistory();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final region = context.read<RegionProvider>().regionCode;
      final api = context.read<YouTubeApiService>();

      final cached = api.getCachedTrending(
        regionCode: region,
        max: 10, // ← Prefetchと必ず一致
      );

      setState(() {
        _trending = cached;
        _trendingLoaded = true;
        _trendingTimestamp = _buildTrendingNow();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _tapAnim.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // 🔥 スクロール方向通知
  // ----------------------------------------------------
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse && !_isScrollingDown) {
      _isScrollingDown = true;
      widget.onScrollChanged?.call(true);
    } else if (direction == ScrollDirection.forward && _isScrollingDown) {
      _isScrollingDown = false;
      widget.onScrollChanged?.call(false);
    }
  }

  // ============================================================
  // 🔎 Search History helpers
  // ============================================================
  Future<void> _loadSearchHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];

      final history =
          list.map((e) => SearchHistoryItem.fromJson(jsonDecode(e))).toList();

      if (!mounted) return;

      setState(() {
        _searchHistory = history;
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveHistory(SearchHistoryItem item) async {
    final next = [
      item,
      ..._searchHistory.where((e) => !(e.type == item.type &&
          e.keyword == item.keyword &&
          e.categoryId == item.categoryId)),
    ];

    if (next.length > _historyMax) {
      next.removeRange(_historyMax, next.length);
    }

    setState(() => _searchHistory = next);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _historyKey,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _removeHistoryItem(String title) async {
    final next =
        _searchHistory.where((e) => e.title != title).toList(growable: false);

    setState(() => _searchHistory = next);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        _historyKey,
        next.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    setState(() => _searchHistory = []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {
      // ignore
    }
  }

  // ----------------------------------------------------
  // 🔍 検索実行
  // ----------------------------------------------------
  Future<void> _executeSearch(String keyword, {bool saveHistory = true}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;

    _debounce?.cancel();
    _focusNode.unfocus();

    setState(() {
      _suggestions = [];
      _isSearchingFromSuggest = true;
    });

    // ✅ 履歴保存（検索確定時）
    // await _saveSearchHistory(kw);

    if (saveHistory) {
      await _saveHistory(
        SearchHistoryItem(
          type: "search",
          title: kw,
          keyword: kw,
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _searchCtrl.clear();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenreVideosScreen(
          categoryId: '0',
          categoryTitle: kw,
          keyword: kw,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _isSearchingFromSuggest = false;
    });
  }

  // ----------------------------------------------------
  // 🔍 デバウンス付きサジェスト
  // ----------------------------------------------------
  void _onSearchChanged(String text) {
    setState(() {});
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 260), () async {
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _networkError = false;
        });
        return;
      }

      setState(() {
        _isLoadingSuggest = true;
        _networkError = false;
      });

      try {
        final region = context.read<RegionProvider>().regionCode;
        final api = context.read<YouTubeApiService>();
        final list = await api.fetchSuggestions(
          text,
          regionCode: region,
        );

        if (!mounted) return;

        setState(() {
          _suggestions = list;
          _isLoadingSuggest = false;
          _networkError = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoadingSuggest = false;
          _suggestions = [];
          _networkError = true;
        });
      }
    });
  }

  // ----------------------------------------------------
  // 🔍 検索フォーム
  // ----------------------------------------------------
  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color searchBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.05);

    final Color actionBg = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _tapAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? const Color(0xFF4F6BFF)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: _focusNode.hasFocus ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 🔍 入力欄
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 1),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            focusNode: _focusNode,
                            onChanged: (text) {
                              _onSearchChanged(text);
                              setState(() {});
                            },
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.90)
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,

                              hintText: AppLocalizations.of(context)!
                                  .genreSearchHeader,

                              hintStyle: TextStyle(
                                fontSize: 17,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),

                              prefixIcon: _focusNode.hasFocus
                                  ? Icon(
                                      Icons.search,
                                      size: 25,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    )
                                  : null,

                              // ★アイコン領域の幅を調整
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),

                              // ★テキスト位置調整
                              contentPadding: const EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 4,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _networkError = false;
                                  });
                                  _focusNode.requestFocus();
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : Colors.black.withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 右アクション
                  Container(
                    width: 52,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: actionBg,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: _isSearchingFromSuggest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.search,
                                size: 22,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _executeSearch(_searchCtrl.text);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildTrendingNow() {
    final now = DateTime.now();

    String two(int n) => n.toString().padLeft(2, '0');

    final date = "${now.month}/${now.day}";
    final time = "${two(now.hour)}:${two(now.minute)}";

    return "$date $time updated";
  }

  // ----------------------------------------------------
  // 🔥 Trending chips
  // ----------------------------------------------------
  Widget _buildTrendingChips(ThemeData theme) {
    logger.i(
        "TrendTips start _trendingLoaded=$_trendingLoaded _trending=${_trending.map((e) => e.keyword).toList()}");

    if (!_trendingLoaded || _trending.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color toggleColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;

          double usedWidth = 0;
          final List<TrendingKeyword> oneLine = [];

          for (final t in _trending) {
            final keyword = t.keyword.trim();
            if (keyword.isEmpty) continue;

            final textPainter = TextPainter(
              text: TextSpan(
                text: keyword,
                style: const TextStyle(fontSize: 14),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();

            final chipWidth = textPainter.width + 48;

            if (usedWidth + chipWidth > maxWidth) break;

            usedWidth += chipWidth + 8;
            oneLine.add(t);
          }

          final List<TrendingKeyword> displayList =
              _showAllTrending ? _trending : oneLine;

          final bool hasMore = _trending.length > oneLine.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "トレンドワード",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 22,
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _trendingTimestamp,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 1.2,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6), // 下線色
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // チップ
              Wrap(
                spacing: 8,
                runSpacing: 1,
                children: displayList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final t = entry.value;

                  final keyword = t.keyword.trim();
                  if (keyword.isEmpty) return const SizedBox.shrink();

                  final bool isTop3 = index < 3;

                  return Material(
                    elevation: isTop3 ? 3 : 1.5,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.transparent,
                    child: ActionChip(
                      pressElevation: 0,
                      label: Text(
                        "#$keyword",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isTop3 ? FontWeight.w700 : FontWeight.w600,
                          color: isTop3 ? Colors.white : Colors.black87,
                        ),
                      ),
                      backgroundColor:
                          isTop3 ? const Color(0xFF7C3AED) : Colors.white,
                      side: isTop3
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFCFD5D5),
                              width: 1,
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      onPressed: () {
                        logger.i("🔥 Trending chip tapped: $keyword");

                        _saveHistory(
                          SearchHistoryItem(
                            type: "trending",
                            title: keyword,
                            keyword: keyword,
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GenreVideosScreen(
                              categoryId: "",
                              categoryTitle: keyword,
                              keyword: keyword,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),

              // トグル
              if (hasMore) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showAllTrending = !_showAllTrending;
                        });

                        logger.i(
                            "🔁 Trending toggle: showAll=$_showAllTrending total=${_trending.length}");
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _showAllTrending
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 26,
                                color: toggleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showAllTrending ? "一部表示" : "全て表示",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: toggleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // 🔥 グループセクション
  // ----------------------------------------------------
  Widget _buildGroupSection(GenreGroup group) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool isTablet = media.size.shortestSide >= 600;

    final int crossAxisCount =
        isTablet ? (isLandscape ? 3 : 2) : (isLandscape ? 2 : 1);

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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          itemCount: group.items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 55,
            mainAxisSpacing: 4,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final cat = group.items[index];
            return _buildCategoryTile(
              context,
              group,
              cat,
              isDark,
            );
          },
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
            _saveHistory(
              SearchHistoryItem(
                type: "category",
                title: cat.name,
                categoryId: cat.id.toString(),
                keyword: cat.query,
              ),
            );

            final groupId = group.groupId;
            final baseCatId = baseCategoryIdsJa[groupId]!.toString();

            if (cat.isOfficial) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreVideosScreen(
                    categoryId: cat.id.toString(),
                    categoryTitle: cat.name,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreVideosScreen(
                    categoryId: baseCatId,
                    categoryTitle: cat.name,
                    keyword: cat.query,
                  ),
                ),
              );
            }
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

  // ============================================================
  // 📜 Suggestions / History pinned box
  // ============================================================
  Widget _buildSuggestionsPinned() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    // ✅ ネットワークエラー
    if (_networkError) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: theme.colorScheme.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.genreNetworkError,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ ローディング（suggest）
    if (_isLoadingSuggest) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // ✅ 入力なし → 履歴
    final bool shouldShowHistory = _searchCtrl.text.isEmpty &&
        _focusNode.hasFocus &&
        _searchHistory.isNotEmpty;

    if (shouldShowHistory) {
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _searchHistory.length + 1, // + header
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            itemBuilder: (_, idx) {
              if (idx == 0) {
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(
                    "最近の検索",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: _clearHistory,
                    child: Text(
                      "消去",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }

              final item = _searchHistory[idx - 1];
              return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: Icon(
                    item.type == "category"
                        ? Icons.category
                        : item.type == "trending"
                            ? Icons.local_fire_department
                            : Icons.search,
                    size: 18,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    onPressed: () => _removeHistoryItem(item.title),
                  ),
                  onTap: () {
                    if (item.type == "category") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenreVideosScreen(
                            categoryId: item.categoryId ?? "",
                            categoryTitle: item.title,
                            keyword: item.keyword,
                          ),
                        ),
                      );
                    } else {
                      _searchCtrl.text = item.keyword ?? "";
                      _executeSearch(item.keyword ?? "", saveHistory: false);
                    }
                  });
            },
          ),
        ),
      );
    }

    // ✅ サジェスト無し → 空
    if (_searchCtrl.text.isEmpty || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ サジェスト一覧
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          itemBuilder: (_, idx) {
            final s = _suggestions[idx];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              leading: Icon(
                Icons.search,
                size: 18,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              title: Text(
                s,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                _searchCtrl.text = s;
                _executeSearch(s);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchFieldWrapper() {
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 600;

    final double maxWidth = isTablet ? 720 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchField(),
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
    if (region != _lastRegion) {
      _lastRegion = region;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _networkError = false;
        });
        if (_searchCtrl.text.isNotEmpty) {
          _onSearchChanged(_searchCtrl.text);
        }
      });
    }

    final groups = getGenreGroupsForRegion(region);

    final bool showHistory = _focusNode.hasFocus &&
        _searchCtrl.text.isEmpty &&
        _searchHistory.isNotEmpty;

    final bool showSuggest = _focusNode.hasFocus &&
        (_networkError ||
            _isLoadingSuggest ||
            showHistory ||
            (_searchCtrl.text.isNotEmpty && _suggestions.isNotEmpty));

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
            const SliverToBoxAdapter(child: SizedBox(height: 60)),

            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedSearchHeaderDelegate(
                safeTop: MediaQuery.of(context).padding.top,
                showSuggestions: showSuggest,
                suggestionsCount: showHistory
                    ? (_searchHistory.length + 1)
                    : _suggestions.length,
                isLoading: _isLoadingSuggest || _isLoadingHistory,
                isError: _networkError,
                searchField: _buildSearchFieldWrapper(),
                suggestions: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSuggestionsPinned(),
                ),
              ),
            ),

            // ✅ pinnedフォーム直後に少し余白
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final media = MediaQuery.of(context);
                  final height = media.size.height;
                  final shortest = media.size.shortestSide;
                  final isTablet = shortest >= 600;
                  final isLandscape =
                      media.orientation == Orientation.landscape;

                  double gap;

                  if (isTablet) {
                    if (isLandscape) {
                      gap = (height * 0.02).clamp(18.0, 28.0);
                    } else {
                      gap = (height * 0.028).clamp(22.0, 36.0);
                    }
                  } else {
                    if (isLandscape) {
                      gap = 12;
                    } else {
                      gap = (height * 0.018).clamp(12.0, 18.0);
                    }
                  }

                  return SizedBox(height: gap);
                },
              ),
            ),

            if (!_focusNode.hasFocus)
              SliverToBoxAdapter(
                child: _buildTrendingChips(theme),
              ),

            if (!_focusNode.hasFocus)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.genreBrowseHeader,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1.2,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

            if (!_focusNode.hasFocus)
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
          ],
        ),
      ),
    );
  }
}

class PinnedSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget searchField;
  final Widget suggestions;

  final double safeTop;
  final bool showSuggestions;

  final int suggestionsCount;
  final bool isLoading;
  final bool isError;

  PinnedSearchHeaderDelegate({
    required this.searchField,
    required this.suggestions,
    required this.safeTop,
    required this.showSuggestions,
    required this.suggestionsCount,
    required this.isLoading,
    required this.isError,
  });

  static const double _topPadding = 16;
  static const double _fieldHeight = 46;
  static const double _gap = 6;

  static const double _suggestMaxHeight = 420;

  static const double _suggestRowHeight = 44;
  static const double _suggestOuterPadding = 16;

  double get _suggestHeight {
    if (!showSuggestions) return 0;

    if (isLoading || isError) return 72;

    final raw = suggestionsCount * _suggestRowHeight + _suggestOuterPadding;
    return raw.clamp(0, _suggestMaxHeight);
  }

  @override
  double get minExtent => safeTop + _topPadding + _fieldHeight;

  @override
  double get maxExtent =>
      minExtent + (showSuggestions ? _gap + _suggestHeight : 0);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final isLandscape = media.orientation == Orientation.landscape;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final safeTopAdjusted = (safeTop * 0.7).clamp(14.0, 28.0);

    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 600;

    return Material(
      color: bg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: safeTopAdjusted + _topPadding,
            height: _fieldHeight,
            child: searchField,
          ),
          if (showSuggestions && (isTablet || !isLandscape))
            Positioned(
              left: 0,
              right: 0,
              top: safeTopAdjusted + _topPadding + _fieldHeight + _gap,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.size.height - keyboardHeight - 120,
                ),
                child: suggestions,
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PinnedSearchHeaderDelegate old) {
    return safeTop != old.safeTop ||
        showSuggestions != old.showSuggestions ||
        suggestionsCount != old.suggestionsCount ||
        isLoading != old.isLoading ||
        isError != old.isError ||
        searchField != old.searchField ||
        suggestions != old.suggestions;
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.text,
    required this.onTap,
    required this.isTop3,
  });

  final String text;
  final VoidCallback onTap;
  final bool isTop3;

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;

    // Top3は紫の“ガラス”、それ以外は白ガラス
    final base = isTop3 ? const Color(0xFF7C3AED) : Colors.white;

    // ガラスの“面”は透明度が肝
    final surfaceOpacity = isTop3 ? 0.30 : 0.55;
    final borderOpacity = isTop3 ? 0.28 : 0.45;

    // ぼかし強度（強すぎると“曇りガラス”になる）
    final blurSigma = isTop3 ? 10.0 : 12.0;

    // 影（いまのスクショだと影が強く見えやすいので控えめ寄り）
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: isTop3 ? 0.18 : 0.12),
      blurRadius: isTop3 ? 10 : 8,
      offset: const Offset(0, 3),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.10),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [shadow],
                border: Border.all(
                  color: Colors.white.withValues(alpha: borderOpacity),
                  width: 1,
                ),
                // “ガラス面”の作り方：半透明 + うっすらグラデ
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    base.withValues(alpha: surfaceOpacity),
                    base.withValues(alpha: surfaceOpacity * 0.65),
                  ],
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                  color: isTop3 ? Colors.white : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
