// lib/widgets/top_bar.dart

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum TopBarMode {
  tabs,
  back,
}

class TopBarSpec {
  static const double barContentHeight = 50.0;
}

class TopBar extends StatefulWidget {
  final TopBarMode mode;

  final int selectedIndex;
  final double pageProgress;
  final bool isTapNavigating;
  final ValueChanged<int>? onTabSelected;

  final String? title;
  final VoidCallback? onBack;

  const TopBar({
    super.key,
    required this.mode,
    this.selectedIndex = 0,
    this.pageProgress = 0,
    this.isTapNavigating = false,
    this.onTabSelected,
    this.title,
    this.onBack,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final ScrollController _scrollController = ScrollController();

  // 🔥 タブ幅（固定）
  static const double _tabWidth = 90;
  int? _pressedIndex;

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

    return Container(
      height: safeTop + 50,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.4),
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
                    Colors.black.withOpacity(0.35),
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
                    Colors.white.withOpacity(0.08),
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
      l.navPopular,
      l.navTopic,
      l.navGenre,
      l.navFavorites,
      l.navSettings,
    ];

    return Row(
      children: [
        // 🔥 ロゴ
        _buildLogo(),

        // 🔥 タブ
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildLogo() {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Image.asset(
          'assets/images/logo.png',
          height: 20, // ← 調整ポイント
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 🔥 タブごとのカラー（TopBar内に追加）
  static const List<Color> _tabColors = [
    Color(0xFFFF7A00), // 人気
    Color(0xFF3B82F6), // トピック
    Color(0xFF10B981), // ジャンル
    Color(0xFFEF4444), // お気に入り
    Color(0xFF757575), // 設定
  ];

  Widget _buildTab(
    BuildContext context, {
    required int index,
    required String label,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    final Color baseColor = _tabColors[index];

    final Color highlightColor = Color.lerp(baseColor, Colors.white, 0.35)!;
    final Color shadowColor = Color.lerp(baseColor, Colors.black, 0.15)!;

    return GestureDetector(
      onTap: () {
        widget.onTabSelected?.call(index);
        _scrollToCenter(index);
      },

      // 🔥 押した瞬間（縮む）
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = null),
      onTapCancel: () => setState(() => _pressedIndex = null),

      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressedIndex == index ? 0.96 : 1.0, // 🔥 ここ

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),

          // 🔥 間隔も微調整（縦余白減らす）
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),

          // 🔥 内側も詰める
          padding: const EdgeInsets.symmetric(horizontal: 10),

          // 🔥 高さダウン
          height: 24,

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

            // 🔥 高さに合わせて少しだけ丸み減らす
            borderRadius: BorderRadius.circular(6),

            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: baseColor
                          .withOpacity(_pressedIndex == index ? 0.2 : 0.35),
                      blurRadius: _pressedIndex == index ? 2 : 4,
                      offset: _pressedIndex == index
                          ? const Offset(0, 1)
                          : const Offset(0, 2),
                    )
                  ]
                : [],
          ),

          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12, // 🔥 少しだけ下げるとバランス◎
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// 🔥 アクティブタブ（既存流用）
// ==========================================================
// class ChromeActiveTab extends StatelessWidget {
//   final String title;
//   final double height;
//
//   const ChromeActiveTab({
//     super.key,
//     required this.title,
//     required this.height,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     return SizedBox(
//       height: height,
//       child: CustomPaint(
//         painter: _ChromeActiveTabPainter(
//           bgColor: theme.scaffoldBackgroundColor,
//           isDark: isDark,
//         ),
//         child: Center(
//           child: Text(
//             title,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.white : Colors.black87,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _ChromeActiveTabPainter extends CustomPainter {
//   final Color bgColor;
//   final bool isDark;
//
//   _ChromeActiveTabPainter({
//     required this.bgColor,
//     required this.isDark,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final bgPaint = Paint()..color = bgColor;
//
//     final borderPaint = Paint()
//       ..color = isDark
//           ? Colors.white.withValues(alpha: 0.08)
//           : Colors.black.withValues(alpha: 0.18)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;
//
//     const double r = 9;
//
//     final path = Path()
//       ..moveTo(0, size.height)
//       ..lineTo(0, r)
//       ..quadraticBezierTo(0, 0, r, 0)
//       ..lineTo(size.width - r, 0)
//       ..quadraticBezierTo(size.width, 0, size.width, r)
//       ..lineTo(size.width, size.height)
//       ..close();
//
//     canvas.drawPath(path, bgPaint);
//
//     final borderPath = Path()
//       ..moveTo(0, size.height)
//       ..lineTo(0, r)
//       ..quadraticBezierTo(0, 0, r, 0)
//       ..lineTo(size.width - r, 0)
//       ..quadraticBezierTo(size.width, 0, size.width, r)
//       ..lineTo(size.width, size.height);
//
//     canvas.drawPath(borderPath, borderPaint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
