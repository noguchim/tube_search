// lib/screens/genre_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/pickup_edit_screen.dart';

import '../data/pickup_selectable_item.dart';
import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/pickup_settings_provider.dart';
import '../providers/region_provider.dart';
import '../services/expanded_video_controller.dart';
import '../services/favorites_service.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../utils/ui_spacing.dart';
import '../widgets/app_dialog.dart';
import '../widgets/expanded_video_overlay.dart';
import '../widgets/section_plain_videos.dart';
import '../widgets/top_bar.dart';

class TopicScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollChanged;

  const TopicScreen({super.key, this.onScrollChanged});

  @override
  State<TopicScreen> createState() => TopicScreenState();
}

class TopicScreenState extends State<TopicScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = false;
  bool _didInitialJump = false;
  double _lastOffset = 0;
  bool _editFabPressed = false;
  static const String _pickupIntroShownKey = 'pickup_intro_shown';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPickupIntroIfNeeded();
    });
  }

  Future<void> _showPickupIntroIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_pickupIntroShownKey) ?? false;

    if (shown) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) {
        return AppDialog(
          title: "ピックアップの編集",
          message: "ピックアップをお好みのジャンルやチャンネルに変更したい場合は、右下のボタンをタップ！",
          actionsAlignment: AppDialogActionsAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/pickup_edit_hint.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );

    await prefs.setBool(_pickupIntroShownKey, true);
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

  Widget _buildEditFab() {
    const Color baseColor = Color(0xFF7C3AED);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PickupEditScreen()),
          );

          if (!mounted) return;

          if (changed == true && mounted) {
            context.read<PickupSettingsProvider>().notifyChanged();
          }
        },
        onHighlightChanged: (value) {
          setState(() {
            _editFabPressed = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _editFabPressed ? 0.18 : 0.35,
                ),
                blurRadius: _editFabPressed ? 8 : 18,
                offset: Offset(0, _editFabPressed ? 4 : 10),
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
              ),
              child: const Center(
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
  // 🧩 本体
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final extraTopGap = isTablet ? 12.0 : 8.0;
    final double topBarOffset = TopBarSpec.total(safeTop) + extraTopGap;
    final pickupRevision = context.watch<PickupSettingsProvider>().revision;
    final expanded = context.watch<ExpandedVideoController>();
    final expandedController = context.read<ExpandedVideoController>();

    context.watch<FavoritesService>();

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFFFFFF),
      floatingActionButton: expanded.video == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: _buildEditFab(),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: CustomScrollView(
              key: const PageStorageKey("genre_scroll"),
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topBarOffset)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: NewArrivalSection(
                      revision: pickupRevision,
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
          if (expanded.video != null)
            Positioned.fill(
              child: ExpandedVideoOverlay(
                video: expanded.video!,
                rank: expanded.rank ?? 1,
                onClose: () {
                  expandedController.close();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class NewArrivalSection extends StatefulWidget {
  final int revision;

  const NewArrivalSection({
    super.key,
    this.revision = 0,
  });

  @override
  State<NewArrivalSection> createState() => _NewArrivalSectionState();
}

class _NewArrivalSectionState extends State<NewArrivalSection> {
  List<YouTubeVideo> videos = [];
  bool isLoading = true;
  final ScrollController _listController = ScrollController();

  String _pickupTimestamp = "";
  bool _isRefreshingPickup = false;
  int _selectedIndex = 0;
  Map<String, List<YouTubeVideo>> cache = {};
  Map<String, DateTime> cacheTime = {};
  String _lastRegion = "JP";
  static const String _pickupSelectedPrefsKey = 'pickup_selected_items';
  static const String _pickupSeenAtPrefsKey = 'pickup_seen_at';

  final Set<String> _unreadPickupKeys = {};
  final Map<String, DateTime> _latestPickupAt = {};
  Map<String, DateTime> _seenPickupAt = {};

  List<PickupSelectableItem> _pickupItems = const [
    PickupSelectableItem(
      type: PickupTargetType.category,
      key: 'category:all',
      title: '全て',
    ),
    PickupSelectableItem(
      type: PickupTargetType.category,
      key: 'category:20',
      title: 'ゲーム',
      categoryId: 20,
    ),
    PickupSelectableItem(
      type: PickupTargetType.category,
      key: 'category:10',
      title: 'トレンド音楽',
      categoryId: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pickupTimestamp = _buildNowLabel();

    _initPickup();
  }

  Future<void> _initPickup() async {
    await _loadPickupItems();
    await _loadSeenPickupAt();

    if (!mounted) return;

    await _refreshUnreadBadgesForAllPickups();
    await fetch();
  }

  Future<void> _loadSeenPickupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSeenAtPrefsKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return;

      final map = <String, DateTime>{};

      decoded.forEach((key, value) {
        final dt = DateTime.tryParse(value.toString());
        if (dt != null) {
          map[key.toString()] = dt;
        }
      });

      if (!mounted) return;

      setState(() {
        _seenPickupAt = map;
      });
    } catch (e) {
      logger.e("Pickup seen load error: $e");
    }
  }

  Future<void> _saveSeenPickupAt() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _seenPickupAt.map((key, value) {
      return MapEntry(key, value.toIso8601String());
    });

    await prefs.setString(
      _pickupSeenAtPrefsKey,
      jsonEncode(data),
    );
  }

  DateTime? _latestPublishedAt(List<YouTubeVideo> list) {
    DateTime? latest;

    for (final video in list) {
      final publishedAt = video.publishedAt;
      if (publishedAt == null) continue;

      if (latest == null || publishedAt.isAfter(latest)) {
        latest = publishedAt;
      }
    }

    return latest;
  }

  void _applyLatestPickupAt({
    required String type,
    required DateTime? latest,
  }) {
    if (latest == null) {
      _unreadPickupKeys.remove(type);
      return;
    }

    _latestPickupAt[type] = latest;

    final seen = _seenPickupAt[type];

    if (seen == null || latest.isAfter(seen)) {
      _unreadPickupKeys.add(type);
    } else {
      _unreadPickupKeys.remove(type);
    }
  }

  Future<void> _refreshUnreadBadgesForAllPickups({
    bool forceRefresh = false,
  }) async {
    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();
    final now = DateTime.now();

    Map<String, List<YouTubeVideo>>? pickupAllData;

    try {
      for (final item in _pickupItems) {
        final type = _pickupTypeOf(item);
        final cacheKey = "${region}_$type";

        List<YouTubeVideo> list;

        if (type == "all" || type == "game" || type == "music") {
          pickupAllData ??= await api.fetchPickupAll(
            regionCode: region,
            forceRefresh: forceRefresh,
          );

          list = pickupAllData[type] ?? [];
        } else {
          list = await api.fetchPickupTargetVideos(
            channelId: item.channelId,
            categoryId: item.categoryId,
            maxResults: 5,
            regionCode: region,
            forceRefresh: forceRefresh,
          );
        }

        cache[cacheKey] = list;
        cacheTime[cacheKey] = now;

        _applyLatestPickupAt(
          type: type,
          latest: _latestPublishedAt(list),
        );
      }

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      logger.e("Pickup unread refresh error: $e");
    }
  }

  Future<void> _markPickupRead(String type) async {
    final latest = _latestPickupAt[type];

    if (latest == null) {
      setState(() {
        _unreadPickupKeys.remove(type);
      });
      return;
    }

    setState(() {
      _seenPickupAt[type] = latest;
      _unreadPickupKeys.remove(type);
    });

    await _saveSeenPickupAt();
  }

  Future<void> _loadPickupItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSelectedPrefsKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return;

      final items = decoded
          .map<PickupSelectableItem>((e) {
            final json = Map<String, dynamic>.from(e as Map);
            final typeName = json['type']?.toString();

            final type = typeName == PickupTargetType.channel.name
                ? PickupTargetType.channel
                : PickupTargetType.category;

            return PickupSelectableItem(
              type: type,
              key: json['key']?.toString() ?? '',
              title: json['title']?.toString() ?? '',
              channelId: json['channelId']?.toString(),
              categoryId: int.tryParse('${json['categoryId'] ?? ''}'),
              pushEnabled: json['pushEnabled'] == true,
            );
          })
          .where((item) {
            return item.key.isNotEmpty && item.title.isNotEmpty;
          })
          .take(3)
          .toList();

      if (!mounted || items.isEmpty) return;

      setState(() {
        _pickupItems = items;
        _selectedIndex = 0;
      });
    } catch (e) {
      logger.e("Pickup prefs load error: $e");
    }
  }

  String _pickupTypeOf(PickupSelectableItem item) {
    if (item.key == 'category:all') return 'all';
    if (item.categoryId == 20) return 'game';
    if (item.categoryId == 10) return 'music';

    if (item.type == PickupTargetType.channel &&
        item.channelId != null &&
        item.channelId!.isNotEmpty) {
      return 'channel:${item.channelId}';
    }

    if (item.categoryId != null) {
      return 'category:${item.categoryId}';
    }

    return 'all';
  }

  @override
  void didUpdateWidget(covariant NewArrivalSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.revision != widget.revision) {
      _reloadPickupItems();
    }
  }

  Future<void> _reloadPickupItems() async {
    await _loadPickupItems();

    if (!mounted) return;

    final pickupSettings = context.read<PickupSettingsProvider>();
    final pendingKey = pickupSettings.pendingPickupKey;

    final nextIndex = pendingKey == null
        ? 0
        : _pickupItems.indexWhere((item) => _pickupTypeOf(item) == pendingKey);

    setState(() {
      _selectedIndex = nextIndex >= 0 ? nextIndex : 0;
      isLoading = true;
      cache.clear();
      cacheTime.clear();

      if (pendingKey != null) {
        _unreadPickupKeys.add(pendingKey);
      }
    });

    _scrollToStart();

    await _refreshUnreadBadgesForAllPickups(forceRefresh: true);
    await fetch(forceRefresh: true);
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  String _buildNowLabel() {
    final now = DateTime.now();

    String two(int n) => n.toString().padLeft(2, '0');

    final date = "${now.month}/${now.day}";
    final time = "${two(now.hour)}:${two(now.minute)}";

    return "$date $time updated";
  }

  Future<void> _refreshPickup() async {
    if (_isRefreshingPickup) return;

    setState(() {
      _isRefreshingPickup = true;
      isLoading = true;
    });

    try {
      await _refreshUnreadBadgesForAllPickups(forceRefresh: true);
      await fetch();

      if (!mounted) return;

      setState(() {
        _pickupTimestamp = _buildNowLabel();
      });
    } catch (e) {
      logger.e("Pickup refresh error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingPickup = false;
        });
      }
    }
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    final region = context.read<RegionProvider>().regionCode;
    final api = context.read<YouTubeApiService>();

    final item = _pickupItems[_selectedIndex];
    final type = _pickupTypeOf(item);

    final now = DateTime.now();
    final key = "${region}_$type";

    logger.i(
      "[Pickup fetch] type=$type title=${item.title} region=$region",
    );

    // =========================
    // 🔥 キャッシュ（UI側）
    // =========================
    final cachedAt = cacheTime[key];

    if (!forceRefresh &&
        cache.containsKey(key) &&
        cachedAt != null &&
        now.difference(cachedAt).inMinutes < 10) {
      logger.i("✅ cache hit: $key");

      setState(() {
        videos = cache[key]!;
        isLoading = false;
      });

      return;
    }

    try {
      List<YouTubeVideo> list;

      // =========================
      // 🔥 既存ピックアップAPI
      // all / game / music は従来通り
      // =========================
      if (type == "all" || type == "game" || type == "music") {
        final allData = await api.fetchPickupAll(
          regionCode: region,
          forceRefresh: forceRefresh,
        );

        list = allData[type] ?? [];
      }

      // =========================
      // 🔍 カテゴリ・チャンネル選択分
      // 専用APIで最大5件取得
      // =========================
      else {
        list = await api.fetchPickupTargetVideos(
          channelId: item.channelId,
          categoryId: item.categoryId,
          maxResults: 5,
          regionCode: region,
          forceRefresh: forceRefresh,
        );
      }

      if (!mounted) return;

      final latest = _latestPublishedAt(list);

      setState(() {
        videos = list;
        isLoading = false;

        cache[key] = list;
        cacheTime[key] = DateTime.now();

        _applyLatestPickupAt(
          type: type,
          latest: latest,
        );
      });
    } catch (e) {
      logger.e("Pickup fetch error: $e");

      if (!mounted) return;

      setState(() {
        videos = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final region = context.watch<RegionProvider>().regionCode;
    if (region != _lastRegion) {
      _lastRegion = region;
      cache.clear();
      cacheTime.clear();
      _latestPickupAt.clear();
      _unreadPickupKeys.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshUnreadBadgesForAllPickups(forceRefresh: true);
        fetch(forceRefresh: true);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(theme),
        _buildHeader(),
        const SizedBox(height: 4),
        _buildContent(),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.newPickupTitle,
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
                        _pickupTimestamp,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _isRefreshingPickup ? null : _refreshPickup,
                      child: Container(
                        height: 22,
                        alignment: Alignment.bottomCenter,
                        child: _isRefreshingPickup
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.refresh,
                                size: 22,
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pickupSettings = context.watch<PickupSettingsProvider>();
    final pendingPickupKey = pickupSettings.pendingPickupKey;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        clipBehavior: Clip.none,
        children: List.generate(_pickupItems.length, (index) {
          final item = _pickupItems[index];
          final type = _pickupTypeOf(item);
          final isSelected = index == _selectedIndex;
          final hasBadge =
              _unreadPickupKeys.contains(type) || pendingPickupKey == type;

          final bgColor = isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDCDCE1));

          final textColor = isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white : Colors.black);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: Ink(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    splashColor: textColor.withValues(alpha: 0.18),
                    highlightColor: textColor.withValues(alpha: 0.08),
                    onTap: () {
                      if (_selectedIndex == index) {
                        _scrollToStart();
                        return;
                      }

                      final currentType =
                          _pickupTypeOf(_pickupItems[_selectedIndex]);

                      _markPickupRead(currentType);

                      final pickupSettings =
                          context.read<PickupSettingsProvider>();
                      if (pickupSettings.pendingPickupKey == currentType) {
                        pickupSettings.clearPendingPush();
                      }

                      final region = context.read<RegionProvider>().regionCode;
                      final key = "${region}_$type";

                      if (cache.containsKey(key)) {
                        setState(() {
                          _selectedIndex = index;
                          videos = cache[key]!;
                          isLoading = false;
                        });

                        _scrollToStart();
                        return;
                      }

                      setState(() {
                        _selectedIndex = index;
                        isLoading = true;
                      });

                      _scrollToStart();

                      fetch();
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 86,
                        maxWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          6,
                          12,
                          6,
                        ),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasBadge)
                const Positioned(
                  top: -4,
                  right: -4,
                  child: _UnreadBadge(),
                ),
            ],
          );
        }),
      ),
    );
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_listController.hasClients) return;

      await _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isNewVideoForCurrentPickup(YouTubeVideo video) {
    final pickupSettings = context.read<PickupSettingsProvider>();

    if (pickupSettings.pendingVideoId == video.id) {
      return true;
    }

    final publishedAt = video.publishedAt;
    if (publishedAt == null) return false;

    if (_pickupItems.isEmpty) return false;

    final type = _pickupTypeOf(_pickupItems[_selectedIndex]);
    final seen = _seenPickupAt[type];

    if (seen == null) return true;

    return publishedAt.isAfter(seen);
  }

  Widget _buildContent() {
    return _buildInner();
  }

  Widget _buildInner() {
    if (isLoading) {
      return const SizedBox(
        height: 255,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (videos.isEmpty) {
      return SizedBox(
        height: 255,
        child: _buildEmpty(),
      );
    }

    return SectionPlainVideos(
      videos: videos,
      isNewVideo: _isNewVideoForCurrentPickup,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            "まだ新着動画がありません",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12.5,
      height: 12.5,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
    );
  }
}
