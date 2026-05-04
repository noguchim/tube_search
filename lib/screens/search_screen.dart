// lib/screens/genre_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/search_history_item.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../services/youtube_api_service.dart';
import '../utils/ui_spacing.dart';
import '../widgets/top_bar.dart';
import 'genre_videos_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const SearchScreen({super.key, this.onScrollChanged});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
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
  double _lastOffset = 0;

  // ============================================================
  // 🔎 Search History
  // ============================================================
  static const String _historyKey = "search_history_v1";
  static const int _historyMax = 12;
  List<SearchHistoryItem> _searchHistory = [];
  bool _isLoadingHistory = false;

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
// 🔍 searchMode判定
// ----------------------------------------------------
  String _detectSearchMode(String keyword) {
    final words = keyword
        .trim()
        .split(RegExp(r'\s+')) // 半角スペース
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.length >= 2) {
      return "and";
    }

    return "or";
  }

  // ----------------------------------------------------
  // 🔍 検索実行
  // ----------------------------------------------------
  Future<void> _executeSearch(String keyword, {bool saveHistory = true}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;

    final searchMode = _detectSearchMode(kw);

    _debounce?.cancel();
    _focusNode.unfocus();

    setState(() {
      _suggestions = [];
      _isSearchingFromSuggest = true;
    });

    if (saveHistory) {
      await _saveHistory(
        SearchHistoryItem(
          type: "search",
          title: kw,
          keyword: kw,
          searchMode: searchMode,
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
          searchMode: searchMode,
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

  // ============================================================
  // 📜 Suggestions / History pinned box
  // ============================================================
  Widget _buildSuggestionsPinned() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final t = AppLocalizations.of(context)!;

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
                    t.recentSearches,
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
                      t.clear,
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
                            searchMode: item.searchMode,
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

    // final double maxWidth = isTablet ? 720 : double.infinity;
    final double maxWidth = 300;

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

    final bool showHistory = _focusNode.hasFocus &&
        _searchCtrl.text.isEmpty &&
        _searchHistory.isNotEmpty;

    final bool showSuggest = _focusNode.hasFocus &&
        (_networkError ||
            _isLoadingSuggest ||
            showHistory ||
            (_searchCtrl.text.isNotEmpty && _suggestions.isNotEmpty));

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
    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 600;

    return Material(
      color: bg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔍 検索バー
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            height: _fieldHeight,
            child: searchField,
          ),

          // 🔽 サジェスト
          if (showSuggestions && (isTablet || !isLandscape))
            Builder(
              builder: (context) {
                final rawHeight = media.size.height - keyboardHeight - 120;

                // 🔥 完全ガード
                final safeHeight = (rawHeight.isFinite && rawHeight > 0)
                    ? rawHeight.clamp(120.0, media.size.height * 0.7)
                    : media.size.height * 0.5;

                return Positioned(
                  left: 0,
                  right: 0,
                  top: _fieldHeight + 10 + _gap, // ← 検索バーの下に出す
                  child: SizedBox(
                    height: safeHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: suggestions,
                    ),
                  ),
                );
              },
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
