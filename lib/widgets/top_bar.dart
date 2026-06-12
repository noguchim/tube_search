// lib/widgets/top_bar.dart

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_logger.dart';

enum TopBarMode {
  tabs,
  back,
}

class TopBarSpec {
  static const double topRowHeight = 42.0;
  static const double tabHeight = 50.0;

  static double total(double safeTop) => safeTop + topRowHeight + tabHeight;
}

class TopBar extends StatefulWidget {
  final TopBarMode mode;

  final int selectedIndex;
  final double pageProgress;
  final bool isTapNavigating;
  final ValueChanged<int>? onTabSelected;

  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onTrendTap;

  const TopBar({
    super.key,
    required this.mode,
    this.selectedIndex = 0,
    this.pageProgress = 0,
    this.isTapNavigating = false,
    this.onTabSelected,
    this.title,
    this.onBack,
    this.onMenuTap,
    this.onSearchTap,
    this.onTrendTap,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final ScrollController _scrollController = ScrollController();

  // 🔥 タブ幅（固定）
  static const double _tabWidth = 90;
  int? _pressedIndex;
  bool isSearchOpen = false;

  @override
  void initState() {
    super.initState();

    // 初期中央寄せ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter(widget.selectedIndex);
    });
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToCenter(widget.selectedIndex);
    }
  }

  void _scrollToCenter(int index) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    double targetOffset;

    // 🔥 ジャンル以降は「完全に右端」
    if (index >= 2) {
      targetOffset = position.maxScrollExtent;
    } else {
      final screenWidth = MediaQuery.of(context).size.width;

      const double logoAreaWidth = 64;

      targetOffset = (index * _tabWidth) -
          ((screenWidth - logoAreaWidth) / 2) +
          (_tabWidth / 2);
    }

    _scrollController.animateTo(
      targetOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xAA000000) : const Color(0xFF282828);
    final double safeTop = MediaQuery.of(context).padding.top;
    logger.i("[Topbar-build]safeTop height=$safeTop");

    return Container(
      height: TopBarSpec.total(safeTop),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // =========================
          // 🔥 全体（SafeArea含む）
          // =========================
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: safeTop), // ← SafeArea

                Expanded(
                  child: _buildTabs(context),
                ),
              ],
            ),
          ),

          // =========================
          // 🔥 上の影（SafeArea含める）
          // =========================
          Positioned(
            left: 0,
            right: 0,
            top: 0, // ← ここが重要（safeTopじゃない）
            child: Container(
              height: safeTop + 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // =========================
          // 🔥 下のハイライト
          // =========================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔥 タブ本体
  // ==========================================================
  Widget _buildTabs(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final tabs = [
      l.navTopic,
      l.navPopular,
      l.navGenre,
      l.navFavorites,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🍔 ハンバーガー（閉じる）
              IconButton(
                icon: const Icon(Icons.menu),
                iconSize: 26,
                color: Colors.white,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),

              // 🟩 ロゴ
              Image.asset(
                'assets/images/logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _buildTrendButton(),
              const SizedBox(width: 4),
              _buildSearchButton(),
              const SizedBox(width: 16),
            ],
          ),
        ),

        // =========================
        // 🔥 下段：タブ
        // =========================
        SizedBox(
          height: 50,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemBuilder: (context, index) {
              return _buildTab(
                context,
                index: index,
                label: tabs[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTrendTap,
          child: const Icon(
            Icons.trending_up,
            size: 25,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onSearchTap,
          child: const Icon(
            Icons.search,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 🔥 タブごとのカラー（TopBar内に追加）
  static const List<Color> _tabColors = [
    Color(0xFF3B82F6), // トピック
    Color(0xFFFF7A00), // 人気
    Color(0xFF10B981), // ジャンル
    Color(0xFFEF4444), // お気に入り
  ];

  Widget _buildTab(
    BuildContext context, {
    required int index,
    required String label,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    final Color baseColor = _tabColors[index];
    final Color highlightColor = Color.lerp(baseColor, Colors.white, 0.35)!;
    final Color shadowColor = Color.lerp(baseColor, Colors.black, 0.2)!;

    return GestureDetector(
      onTap: () {
        widget.onTabSelected?.call(index);
        _scrollToCenter(index);
      },
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = null),
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressedIndex == index ? 0.96 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minWidth: 94),

          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          // ← 少し詰める
          padding: const EdgeInsets.symmetric(horizontal: 12),

          height: 34,
          // 🔥 26 → 34 にUP

          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? null : const Color(0xFF3A3A3A),

            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      highlightColor,
                      baseColor,
                      shadowColor,
                    ],
                  )
                : null,

            borderRadius: BorderRadius.circular(6),

            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [], // ← これ重要
          ),
          child: Stack(
            children: [
              Center(
                child: index == 0
                    // 🏠 ホーム
                    ? const SizedBox(
                        width: 55,
                        child: Center(
                          child: Icon(
                            Icons.home,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      )

                    // 📝 その他
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
              ),
              // =========================
              // 🔥 上ハイライト
              // =========================
              if (isSelected)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // =========================
              // 🔥 下の締め
              // =========================
              if (isSelected)
                Positioned(
                  bottom: 0,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
