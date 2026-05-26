import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/trending_keyword.dart';
import '../l10n/app_localizations.dart';
import '../providers/region_provider.dart';
import '../screens/genre_videos_screen.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';

class TrendWordSheet extends StatefulWidget {
  const TrendWordSheet({super.key});

  @override
  State<TrendWordSheet> createState() => _TrendWordSheetState();
}

class _TrendWordSheetState extends State<TrendWordSheet> {
  List<TrendingKeyword> _trending = [];
  bool _trendingLoaded = false;
  String _trendingTimestamp = "";
  bool _isRefreshingTrending = false;

  @override
  void initState() {
    super.initState();
    _refreshTrending(forceRefresh: false);
  }

  String _buildTrendingNow() {
    final now = DateTime.now();

    String two(int n) => n.toString().padLeft(2, '0');

    final date = "${now.month}/${now.day}";
    final time = "${two(now.hour)}:${two(now.minute)}";

    return "$date $time updated";
  }

  Future<void> _refreshTrending({
    bool forceRefresh = true,
  }) async {
    if (_isRefreshingTrending) return;

    setState(() {
      _isRefreshingTrending = true;
    });

    try {
      final api = context.read<YouTubeApiService>();
      final region = context.read<RegionProvider>().regionCode;

      final data = await api.fetchContentJson(
        type: "trend",
        regionCode: region,
        forceRefresh: forceRefresh,
      );

      final list = data["items"] as List;
      final result = list.map((e) => TrendingKeyword.fromJson(e)).toList();

      if (!mounted) return;

      setState(() {
        _trending = result;
        _trendingLoaded = true;
        _trendingTimestamp = _buildTrendingNow();
      });
    } catch (e) {
      logger.e("Trending refresh error: $e");

      if (!mounted) return;

      setState(() {
        _trendingLoaded = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingTrending = false;
        });
      }
    }
  }

  void _openKeyword(String keyword) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenreVideosScreen(
          categoryId: "",
          categoryTitle: keyword,
          keyword: keyword,
          searchMode: "or",
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final t = AppLocalizations.of(context)!;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.trendWords,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _isRefreshingTrending
                    ? null
                    : () => _refreshTrending(forceRefresh: true),
                child: Container(
                  height: 22,
                  alignment: Alignment.bottomCenter,
                  child: _isRefreshingTrending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh,
                          size: 24,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetGlass({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.black.withValues(alpha: 0.32),
                      Colors.black.withValues(alpha: 0.20),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.44),
                      Colors.white.withValues(alpha: 0.28),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.55),
                width: 0.7,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.55,
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: _buildSheetGlass(
          context: context,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              28 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: _buildTitle(theme),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _trendingLoaded
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _trending.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final keyword = item.keyword.trim();

                                if (keyword.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final isTop3 = index < 3;

                                return Material(
                                  elevation: isTop3 ? 3 : 1.5,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(22),
                                  color: Colors.transparent,
                                  child: ActionChip(
                                    pressElevation: 0,
                                    label: Text(
                                      "#$keyword",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isTop3
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isTop3
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    backgroundColor: isTop3
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white,
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
                                      logger.i(
                                        "🔥 Trending chip tapped: $keyword",
                                      );
                                      _openKeyword(keyword);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
