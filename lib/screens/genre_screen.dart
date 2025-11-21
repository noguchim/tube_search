// lib/screens/genre_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../services/youtube_api_service.dart';
import '../data/genre_groups.dart';
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

  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoadingSuggest = false;

  bool _isScrollingDown = false;

  /// 🔥 初回だけ “持ち上がり” を実行
  bool _isFirstTap = true;

  /// 🔥 サジェストをタップして検索結果に遷移中かどうか
  bool _isSearchingFromSuggest = false;

  /// 🔥 アニメーション（scale + shadow）
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
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isLoadingSuggest = true);
      final list = await _apiService.fetchSuggestions(text);

      if (!mounted) return;

      setState(() {
        _suggestions = list;
        _isLoadingSuggest = false;
      });
    });
  }

  // ----------------------------------------------------
  // 🔥 検索バータップ → 浮き上がり → 遅延吸収 → キーボード
  // ----------------------------------------------------
  Future<void> _onTapSearchField() async {
    if (_isFirstTap) {
      _isFirstTap = false;

      // ① アニメーション開始
      _tapAnim.forward();

      // ② iOS のキーボード遅延を吸収（自然）
      await Future.delayed(const Duration(milliseconds: 280));

      // ③ キーボードフォーカス
      _focusNode.requestFocus();

      // ④ 戻す（キーボード起動後なので自然に見える）
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) _tapAnim.reverse();
    } else {
      // 2回目以降は普通にフォーカス
      _focusNode.requestFocus();
    }
  }

  // ----------------------------------------------------
  // 🔍 検索フォーム（浮き上がり＋右端ミニローダー）
  // ----------------------------------------------------
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AnimatedBuilder(
        animation: _tapAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Material(
              elevation: _shadowAnim.value,
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  // TextField 本体
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Color(0xFF475569)),
                        hintText: "検索ワードを入力...",
                      ),
                    ),
                  ),

                  // 🔄 サジェスト→遷移中の小さなローダー
                  if (_isSearchingFromSuggest)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),

                  // 🔥 上部をキャッチする透明のタップレイヤー
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
  // 🔥 グループセクション
  // ----------------------------------------------------
  Widget _buildGroupSection(GenreGroup group) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // グループタイトル（上広め / 下きつめ）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(group.icon, color: group.color, size: 22),
                const SizedBox(width: 8),
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 グループ内カテゴリ一覧（タップで動画画面へ）
          ...group.items.map((cat) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final groupId = group.groupId; // 例: G01
                    final baseCatId = baseCategoryIds[groupId]!.toString();

                    if (cat.isOfficial) {
                      // 公式カテゴリ → 公式IDでそのまま遷移
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
                      // 独自カテゴリ → ベースカテゴリID + query
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenreVideosScreen(
                            categoryId: baseCatId, // 公式カテゴリID
                            categoryTitle: cat.name,
                            keyword: cat.query, // 追加キーワード
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.label,
                            size: 22, color: Color(0xFF607D8B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[500]),
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
  // 🔍 サジェスト一覧
  // ----------------------------------------------------
  Widget _buildSuggestions() {
    if (_searchCtrl.text.isEmpty || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoadingSuggest)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ..._suggestions.map(
                (s) => ListTile(
              dense: true,
              leading: const Icon(Icons.search, size: 20),
              title: Text(s),
              onTap: () async {
                // ① デバウンス停止
                _debounce?.cancel();

                final kw = s;

                // ② 選択内容を入力欄に反映して見せる
                _searchCtrl.text = kw;
                _focusNode.unfocus();

                // ③ サジェストを閉じてミニローダーON
                setState(() {
                  _suggestions = [];
                  _isSearchingFromSuggest = true;
                });

                // ④ UXのため 0.25秒だけ“選んだ感”を見せる
                await Future.delayed(const Duration(milliseconds: 1000));

                if (!mounted) return;

                // ⑤ 結果画面へ遷移（キーワード検索モード）
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenreVideosScreen(
                      categoryId: '0', // 特別扱い用ダミーID
                      categoryTitle: kw,
                      keyword: kw,
                    ),
                  ),
                );

                // ⑥ 戻ってきたらローダーOFF
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
  // 🧩 全体 UI
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 82,
            flexibleSpace: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  "ジャンル別人気",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "検索して探す",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // 🔍検索フォーム
          SliverToBoxAdapter(child: _buildSearchField()),

          // 🔍サジェスト
          SliverToBoxAdapter(child: _buildSuggestions()),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                "ジャンルから探す",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // 🔥 ジャンルグループ一覧
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, groupIndex) {
                final group = genreGroups[groupIndex];
                return _buildGroupSection(group);
              },
              childCount: genreGroups.length,
            ),
          ),

          // 最後の余白
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
