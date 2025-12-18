// lib/screens/genre_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../data/genre_groups.dart';
import '../services/youtube_api_service.dart';

import '../widgets/custom_glass_app_bar.dart';
import 'genre_videos_screen.dart';

class GenreScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const GenreScreen({super.key, this.onScrollChanged});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen>
    with SingleTickerProviderStateMixin {
  final YouTubeApiService _apiService = YouTubeApiService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _networkError = false;

  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoadingSuggest = false;

  bool _isScrollingDown = false;

  bool _isFirstTap = true;
  bool _isSearchingFromSuggest = false;

  late AnimationController _tapAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _shadowAnim;

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
    _shadowAnim = Tween<double>(begin: 6.0, end: 10.0).animate(
      CurvedAnimation(parent: _tapAnim, curve: Curves.easeOut),
    );
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

  // ----------------------------------------------------
  // 🔍 デバウンス付きサジェスト
  // ----------------------------------------------------
  void _onSearchChanged(String text) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 260), () async {
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _networkError = false; // リセット
        });
        return;
      }

      setState(() {
        _isLoadingSuggest = true;
        _networkError = false; // 通信前にクリア
      });

      try {
        final list = await _apiService.fetchSuggestions(text);

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
          _networkError = true; // ← ★ エラーフラグON
        });
      }
    });
  }

  Future<void> _onTapSearchField() async {
    if (_isFirstTap) {
      _isFirstTap = false;

      _tapAnim.forward();
      await Future.delayed(const Duration(milliseconds: 280));
      _focusNode.requestFocus();
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) _tapAnim.reverse();
    } else {
      _focusNode.requestFocus();
    }
  }

  // ----------------------------------------------------
  // 🔍 検索フォーム（Dark対応）
  // ----------------------------------------------------
  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🍎 Apple系：検索バーはカードより明るい透明レイヤー
    final Color searchBg = isDark
        ? Colors.white.withValues(alpha: 0.12)   // ← 12〜16% がApple標準
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AnimatedBuilder(
        animation: _tapAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Material(
              elevation: 0, // ← Appleの検索バーは影0
              borderRadius: BorderRadius.circular(14),
              color: Colors.transparent, // ← Material自体に色をつけない
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: searchBg, // ← Apple検索バーの透明感
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10) // 輪郭の光
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.90)
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                        hintText: "検索ワードを入力...",
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  if (_isSearchingFromSuggest)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),

                  // ← 検索バータップ拡張
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onTapSearchField,
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

  // ----------------------------------------------------
  // 🔍 サジェスト一覧（Dark対応）
  // ----------------------------------------------------
  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    // -------------------------
    // 💥 ネットワークエラー表示
    // -------------------------
    if (_networkError) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "ネットワークに接続できません",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // -------------------------
    // 📭 空 or サジェストなし → 非表示
    // -------------------------
    if (_searchCtrl.text.isEmpty || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // -------------------------
    // 🔄 ローディング
    // -------------------------
    if (_isLoadingSuggest) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // -------------------------
    // 🔍 サジェストリスト
    // -------------------------
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._suggestions.map(
                (s) => ListTile(
              dense: true,
              leading: Icon(
                Icons.search,
                size: 20,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              title: Text(
                s,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () async {
                _debounce?.cancel();

                final kw = s;
                _searchCtrl.text = kw;
                _focusNode.unfocus();

                setState(() {
                  _suggestions = [];
                  _isSearchingFromSuggest = true;
                });

                await Future.delayed(const Duration(milliseconds: 1500));

                if (!mounted) return;

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
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 🔥 グループセクション（Dark対応）
  // ----------------------------------------------------
  Widget _buildGroupSection(GenreGroup group) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          const SizedBox(height: 10),

          // 各カテゴリ
          ...group.items.map((cat) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Material(
                color: cardColor,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final groupId = group.groupId;
                    final baseCatId = baseCategoryIds[groupId]!.toString();

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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.label,
                          size: 22,
                          color:
                          isDark ? Colors.white70 : const Color(0xFF607D8B),
                        ),
                        const SizedBox(width: 12),
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
                          color:
                          isDark ? Colors.white54 : Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 🧩 本体（Darkテーマ背景対応）
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 70,
            flexibleSpace: const CustomGlassAppBar(
              title: 'ジャンル別人気',
            ),
          ),

          // --- 見出し ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "検索して探す",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildSearchField()),
          SliverToBoxAdapter(child: _buildSuggestions()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                "ジャンルから探す",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, idx) => _buildGroupSection(genreGroups[idx]),
              childCount: genreGroups.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
