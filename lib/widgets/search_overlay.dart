import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/search_history_item.dart';
import '../l10n/app_localizations.dart';
import '../providers/recommendation_history_provider.dart';
import '../providers/region_provider.dart';
import '../providers/search_ui_provider.dart';
import '../screens/genre_videos_screen.dart';
import '../services/youtube_api_service.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final bool isOpen;

  const SearchOverlay({
    super.key,
    required this.onClose,
    required this.isOpen,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<String> _suggestions = [];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoadingSuggest = false;
  bool _isSearchingFromSuggest = false;
  late AnimationController _tapAnim;
  late Animation<double> _scaleAnim;
  bool _networkError = false;
  List<SearchHistoryItem> _searchHistory = [];

  @override
  void initState() {
    super.initState();

    final search = context.read<SearchUIProvider>();
    search.loadHistory();

    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _tapAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _focusNode.unfocus();
    _focusNode.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tapAnim.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 260), () async {
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _networkError = false;
          _isLoadingSuggest = false;
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

  // ==========================================
  // 🔍 UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + 1;
    final safeTop = MediaQuery.of(context).padding.top;

    return FocusScope(
      autofocus: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Stack(
            children: [
              Positioned(
                top: safeTop + 90,
                left: 0,
                right: 0,
                bottom: bottomInset + 60,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildSuggestions(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: GestureDetector(
                  onTap: () {},
                  child: _buildSearchField(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeSearch(String keyword, {bool saveHistory = true}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;

    // ✅ close前に必要なものを取得
    final navigator = Navigator.of(context, rootNavigator: true);
    final searchProvider = context.read<SearchUIProvider>();
    final recommendationHistory = context.read<RecommendationHistoryProvider>();

    final searchMode = _detectSearchMode(kw);

    _debounce?.cancel();
    _focusNode.unfocus();

    if (saveHistory) {
      await searchProvider.saveHistory(
        SearchHistoryItem(
          type: "search",
          title: kw,
          keyword: kw,
          searchMode: searchMode,
        ),
      );
    }

    await recommendationHistory.recordSearchKeyword(kw);

    // ✅ ここでOverlayは破棄されてもOK
    widget.onClose();

    await Future.delayed(const Duration(milliseconds: 200));

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => GenreVideosScreen(
          categoryId: '0',
          categoryTitle: kw,
          keyword: kw,
          searchMode: searchMode,
        ),
      ),
    );

    // Overlayは破棄済みの可能性が高いので、基本不要
    if (mounted) {
      setState(() {
        _isSearchingFromSuggest = false;
      });
    }
  }

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

  Widget _buildSearchField() {
    final bool canSearch = _searchCtrl.text.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: _tapAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white, // ← 完全固定
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08), // ← 固定
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // =========================
                  // 🔍 入力欄
                  // =========================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 1),
                      child: TextField(
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        onChanged: (text) {
                          _onSearchChanged(text);
                        },
                        onSubmitted: (text) {
                          final kw = text.trim();

                          if (kw.isEmpty) {
                            // 🔥 フォーカスを即戻し再描画させない
                            _focusNode.requestFocus();
                            return;
                          }

                          _executeSearch(kw);
                        },
                        style: const TextStyle(
                          color: Colors.black87, // ← 固定
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              AppLocalizations.of(context)!.genreSearchHeader,
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 24,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =========================
                  // 🔥 右アクション（検索ボタン）
                  // =========================
                  Container(
                    width: 52,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06), // ← 固定
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: _isSearchingFromSuggest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black, // ← 変更（白→黒）
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.search,
                                size: 24,
                                color: canSearch
                                    ? Colors.black87
                                    : Colors.black.withValues(alpha: 0.3),
                              ),
                              onPressed: canSearch
                                  ? () {
                                      final kw = _searchCtrl.text.trim();
                                      if (kw.isEmpty) return;
                                      _executeSearch(kw);
                                    }
                                  : null,
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

  // ==========================================
  // 🔍 サジェスト
  // ==========================================
  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    // =========================
    // ❌ ネットワークエラー
    // =========================
    if (_networkError) {
      return _buildCard(
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: theme.colorScheme.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.genreNetworkError,
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

    // =========================
    // ⏳ ローディング
    // =========================
    if (_isLoadingSuggest) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // =========================
    // 📜 履歴表示
    // =========================
    _searchHistory = context.watch<SearchUIProvider>().history;
    final bool showHistory =
        _searchCtrl.text.isEmpty && _searchHistory.isNotEmpty;

    if (showHistory) {
      return _buildCard(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _searchHistory.length + 1,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          itemBuilder: (_, idx) {
            // 🔹 ヘッダー
            if (idx == 0) {
              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                title: Text(
                  t.recentSearches,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    context.read<SearchUIProvider>().clearHistory();
                  },
                  child: Text(
                    t.clear,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                onPressed: () {
                  context
                      .read<SearchUIProvider>()
                      .removeHistoryItem(item.title);
                },
              ),
              onTap: () {
                _searchCtrl.text = item.keyword ?? "";
                _executeSearch(item.keyword ?? "", saveHistory: false);
              },
            );
          },
        ),
      );
    }

    // =========================
    // 🔍 サジェストなし
    // =========================
    if (_searchCtrl.text.isEmpty || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // =========================
    // 🔍 サジェスト一覧
    // =========================
    return _buildCard(
      child: ListView.separated(
        shrinkWrap: true,
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
    );
  }

  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF282828) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(
        maxHeight: 380,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
