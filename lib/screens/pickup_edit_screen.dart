import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/base_genre_models.dart';
import '../data/genre_provider.dart';
import '../data/pickup_selectable_item.dart';
import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/pickup_settings_provider.dart';
import '../providers/push_subscription_provider.dart';
import '../providers/region_provider.dart';
import '../services/favorites_service.dart';
import '../services/push_token_store.dart';
import '../services/youtube_api_service.dart';
import '../utils/app_logger.dart';
import '../widgets/app_dialog.dart';

class PickupEditScreen extends StatefulWidget {
  const PickupEditScreen({super.key});

  @override
  State<PickupEditScreen> createState() => _PickupEditScreenState();
}

class _PickupEditScreenState extends State<PickupEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<PickupSelectableItem> _channels = [];
  bool _channelsLoading = true;
  String? _loadedRegion;
  final Map<String, List<GenreGroup>> _genreGroupsCache = {};
  final Map<String, List<PickupSelectableItem>> _channelCache = {};
  static double _savedGenreOffset = 0;
  static double _savedChannelOffset = 0;

  late final ScrollController _genreScrollController;
  late final ScrollController _channelScrollController;
  static const int _maxSelectedCount = 3;
  static const int _minSelectedCount = 1;
  static const String _pickupSelectedPrefsKey = 'pickup_selected_items';
  static const String _pickupPushDefaultsSignaturePrefsKey =
      'pickup_push_defaults_signature';
  final Set<String> _expandedGenreGroups = {};
  final Set<String> _expandedChannelSections = {};
  bool _isSaving = false;
  bool _didLoadSelectedItems = false;

  List<PickupSelectableItem> _selected = [];

  List<PickupSelectableItem> _defaultSelectedItems(AppLocalizations l) {
    return [
      PickupSelectableItem(
        type: PickupTargetType.category,
        key: 'category:recommended',
        title: l.pickupRecommended,
      ),
      PickupSelectableItem(
        type: PickupTargetType.category,
        key: 'category:20',
        title: l.commonGame,
        categoryId: 20,
      ),
      PickupSelectableItem(
        type: PickupTargetType.category,
        key: 'category:10',
        title: l.pickupTrendMusic,
        categoryId: 10,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _genreScrollController = ScrollController(
      initialScrollOffset: _savedGenreOffset,
    );

    _channelScrollController = ScrollController(
      initialScrollOffset: _savedChannelOffset,
    );

    _genreScrollController.addListener(() {
      if (_genreScrollController.hasClients) {
        _savedGenreOffset = _genreScrollController.offset;
      }
    });

    _channelScrollController.addListener(() {
      if (_channelScrollController.hasClients) {
        _savedChannelOffset = _channelScrollController.offset;
      }
    });

    _restoreScrollOffset(_genreScrollController, _savedGenreOffset);
  }

  Future<void> _loadSelectedItems(AppLocalizations l) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSelectedPrefsKey);

    // 初回起動など未保存なら、didChangeDependenciesで入れた初期値のまま
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

            final itemKey = json['key']?.toString() == 'category:all'
                ? 'category:recommended'
                : json['key']?.toString() ?? '';

            return PickupSelectableItem(
              type: type,
              key: itemKey,
              title: itemKey == 'category:recommended'
                  ? l.pickupRecommended
                  : json['title']?.toString() ?? '',
              channelId: json['channelId']?.toString(),
              categoryId: int.tryParse('${json['categoryId'] ?? ''}'),
              pushEnabled: json['pushEnabled'] == true,
            );
          })
          .where((item) {
            return item.key.isNotEmpty && item.title.isNotEmpty;
          })
          .take(_maxSelectedCount)
          .toList();

      if (!mounted || items.isEmpty) return;

      setState(() {
        _selected = items;
      });
    } catch (e) {
      logger.e("Pickup edit prefs load error: $e");
      // 壊れた保存値なら初期値のまま使う
    }
  }

  Future<void> _saveSelectedItems({
    required Set<String> checkedKeys,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = _selected.map((item) {
      final pushKey = _pushKeyOf(item);

      return {
        'type': item.type.name,
        'key': item.key,
        'title': item.title,
        'channelId': item.channelId,
        'categoryId': item.categoryId,
        'pushEnabled': pushKey.isNotEmpty && checkedKeys.contains(pushKey),
      };
    }).toList();

    await prefs.setString(
      _pickupSelectedPrefsKey,
      jsonEncode(data),
    );

    await prefs.setString(
      _pickupPushDefaultsSignaturePrefsKey,
      _pickupSignature(_selected),
    );
  }

  String _pickupSignature(List<PickupSelectableItem> items) {
    final keys = items.map((item) => item.key).toList()..sort();
    return keys.join('|');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final region = context.read<RegionProvider>().regionCode;
    final l = AppLocalizations.of(context)!;

    if (!_didLoadSelectedItems) {
      _didLoadSelectedItems = true;
      _selected = _defaultSelectedItems(l);
      _loadSelectedItems(l);
      unawaited(context.read<FavoritesService>().loadFavorites());
    }

    logger.i(
        "[PickupEdit] didChangeDependencies region=$region loaded=$_loadedRegion");

    if (_loadedRegion == region) return;

    _fetchChannels();
  }

  @override
  void dispose() {
    _savedGenreOffset = _genreScrollController.hasClients
        ? _genreScrollController.offset
        : _savedGenreOffset;

    _savedChannelOffset = _channelScrollController.hasClients
        ? _channelScrollController.offset
        : _savedChannelOffset;

    _genreScrollController.dispose();
    _channelScrollController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  bool _isSelected(PickupSelectableItem item) {
    return _selected.any((e) => e.key == item.key);
  }

  void _toggle(PickupSelectableItem item) {
    setState(() {
      final index = _selected.indexWhere((e) => e.key == item.key);

      // 選択済みなら解除
      if (index >= 0) {
        // 最後の1件は解除させない
        if (_selected.length <= _minSelectedCount) {
          return;
        }

        _selected.removeAt(index);
        return;
      }

      // 上限3件なら、古い選択を外して新しい選択に置き換え
      if (_selected.length >= _maxSelectedCount) {
        _selected.removeAt(0);
      }

      _selected.add(item);
    });
  }

  List<GenreGroup> _getGenreGroups(String region) {
    return _genreGroupsCache.putIfAbsent(
      region,
      () => getGenreGroupsForRegion(region),
    );
  }

  Future<void> _fetchChannels() async {
    final region = context.read<RegionProvider>().regionCode;

    final cached = _channelCache[region];
    if (cached != null) {
      setState(() {
        _channels = cached;
        _channelsLoading = false;
        _loadedRegion = region;
      });

      _restoreScrollOffset(_channelScrollController, _savedChannelOffset);
      return;
    }

    final api = context.read<YouTubeApiService>();

    setState(() {
      _channelsLoading = true;
    });

    try {
      final channels = await api.fetchPickupChannels(
        regionCode: region,
      );

      if (!mounted) return;

      setState(() {
        _channelCache[region] = channels;
        _channels = channels;
        _channelsLoading = false;
        _loadedRegion = region;
      });

      _restoreScrollOffset(_channelScrollController, _savedChannelOffset);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _channels = [];
        _channelsLoading = false;
        _loadedRegion = region;
      });
    }
  }

  void _restoreScrollOffset(
    ScrollController controller,
    double offset,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.hasClients) return;

      final max = controller.position.maxScrollExtent;
      final safeOffset = offset.clamp(0.0, max);

      controller.jumpTo(safeOffset);
    });
  }

  Widget _buildChip(
    String value, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final maxTextWidth = MediaQuery.of(context).size.width - 120;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.check_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxTextWidth,
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PickupItemSection> _buildChannelSections(
    List<PickupSelectableItem> channels,
    Map<int, String> categoryNameById,
    Map<int, int> categoryOrderById,
  ) {
    final l = AppLocalizations.of(context)!;
    final grouped = <String, List<PickupSelectableItem>>{};

    for (final item in channels) {
      final groupName = item.subtitle?.trim();

      final key = groupName != null && groupName.isNotEmpty
          ? 'group:$groupName'
          : 'category:${item.categoryId ?? 0}';

      grouped.putIfAbsent(key, () => []).add(item);
    }

    for (final items in grouped.values) {
      items.sort((a, b) {
        final priority = b.priority.compareTo(a.priority);
        if (priority != 0) return priority;

        return a.title.compareTo(b.title);
      });
    }

    final sections = grouped.entries.map((entry) {
      final first = entry.value.first;

      final groupName = first.subtitle?.trim();

      final title = groupName != null && groupName.isNotEmpty
          ? groupName
          : categoryNameById[first.categoryId] ??
              l.pickupEditCategoryFallback('${first.categoryId ?? "-"}');

      return PickupItemSection(
        title: title,
        items: entry.value,
      );
    }).toList();

    sections.sort((a, b) {
      final aCategory = a.items.first.categoryId;
      final bCategory = b.items.first.categoryId;
      final aOrder = categoryOrderById[aCategory] ?? 9999;
      final bOrder = categoryOrderById[bCategory] ?? 9999;
      final category = aOrder.compareTo(bOrder);
      if (category != 0) return category;

      return a.title.compareTo(b.title);
    });

    return sections;
  }

  Widget _buildChannelSectionWrap(
    List<PickupSelectableItem> channels,
    Map<int, String> categoryNameById,
    Map<int, int> categoryOrderById,
  ) {
    final sections = _buildChannelSections(
      channels,
      categoryNameById,
      categoryOrderById,
    );

    return SingleChildScrollView(
      key: const PageStorageKey('pickup_channel_scroll'),
      controller: _channelScrollController,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          final sectionKey = section.title;
          final expanded = _expandedChannelSections.contains(sectionKey);

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: section.title,
                  collapsed: !expanded,
                  leftPadding: 8,
                  onTap: () {
                    setState(() {
                      if (expanded) {
                        _expandedChannelSections.remove(sectionKey);
                      } else {
                        _expandedChannelSections.add(sectionKey);
                      }
                    });
                  },
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: section.items.map((item) {
                      return _buildChip(
                        item.title,
                        selected: _isSelected(item),
                        onTap: () => _toggle(item),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<PickupSelectableItem> _buildFavoriteChannelItems(
    List<YouTubeVideo> favorites,
    String region,
  ) {
    final byChannelId = <String, PickupSelectableItem>{};

    for (final video in favorites) {
      final channelId = video.channelId?.trim();
      final channelTitle = video.channelTitle.trim();

      if (channelId == null || channelId.isEmpty || channelTitle.isEmpty) {
        continue;
      }

      byChannelId.putIfAbsent(
        channelId,
        () => PickupSelectableItem.fromChannel(
          channelId: channelId,
          channelTitle: channelTitle,
          region: region,
        ),
      );
    }

    return byChannelId.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Widget _buildFavoriteChannelSectionWrap(
    List<PickupSelectableItem> channels,
  ) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.pickupEditFavoriteEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.pickupEditFavoriteEmptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const PageStorageKey('pickup_favorite_channel_scroll'),
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        32,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: channels.map((item) {
          return _buildChip(
            item.title,
            selected: _isSelected(item),
            onTap: () => _toggle(item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreSectionWrap(
    List<GenreGroup> groups,
  ) {
    const excludedCategoryIds = {-1, 12, 13};

    final visibleGroups = groups.map((group) {
      final items = group.items
          .where((category) => !excludedCategoryIds.contains(category.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return MapEntry(group, items);
    }).where((entry) {
      return entry.value.isNotEmpty;
    }).toList();

    final l = AppLocalizations.of(context)!;
    final allItem = PickupSelectableItem(
      type: PickupTargetType.category,
      key: 'category:recommended',
      title: l.pickupRecommended,
    );

    return SingleChildScrollView(
      key: const PageStorageKey('pickup_genre_scroll'),
      controller: _genreScrollController,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                allItem.title,
                selected: _isSelected(allItem),
                onTap: () => _toggle(allItem),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...visibleGroups.map((entry) {
            final group = entry.key;
            final items = entry.value;
            final groupKey = group.groupId;
            final expanded = _expandedGenreGroups.contains(groupKey);

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: group.name,
                    collapsed: !expanded,
                    leadingIcon: group.icon,
                    leadingColor: group.color,
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expandedGenreGroups.remove(groupKey);
                        } else {
                          _expandedGenreGroups.add(groupKey);
                        }
                      });
                    },
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: items.map((category) {
                        final item = PickupSelectableItem.fromCategory(
                          group: group,
                          category: category,
                        );

                        return _buildChip(
                          item.title,
                          selected: _isSelected(item),
                          onTap: () => _toggle(item),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool collapsed,
    required VoidCallback onTap,
    IconData? leadingIcon,
    Color? leadingColor,
    double leftPadding = 0,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: leftPadding,
            right: 8,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 18,
                  color: leadingColor,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 26,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pushKeyOf(PickupSelectableItem item) {
    if (item.type == PickupTargetType.channel) {
      return "channel:${item.channelId ?? ''}";
    }

    return "category:${item.categoryId ?? ''}";
  }

  bool _isPushSubscribable(PickupSelectableItem item) {
    if (item.key == 'category:recommended' || item.key == 'category:all') {
      return false;
    }

    if (item.type == PickupTargetType.channel) {
      return item.channelId != null && item.channelId!.isNotEmpty;
    }

    return item.categoryId != null;
  }

  Future<void> _showPickupConfirmDialog() async {
    final l = AppLocalizations.of(context)!;

    final checkedKeys = <String>{};

    for (final item in _selected) {
      if (!_isPushSubscribable(item)) continue;

      checkedKeys.add(_pushKeyOf(item));
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              title: l.pickupEditDialogTitle,
              message: l.pickupEditDialogMessage,
              actionsAlignment: AppDialogActionsAlignment.end,
              actions: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: Text(
                    l.commonCancel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _savePickupWithNotifications(
                            checkedKeys: checkedKeys,
                            dialogContext: dialogContext,
                          );
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.commonOk),
                ),
              ],
              child: Column(
                children: _selected.map((item) {
                  final subscribable = _isPushSubscribable(item);
                  final key = _pushKeyOf(item);
                  final checked = subscribable && checkedKeys.contains(key);

                  return InkWell(
                    onTap: subscribable
                        ? () {
                            setDialogState(() {
                              if (checked) {
                                checkedKeys.remove(key);
                              } else {
                                checkedKeys.add(key);
                              }
                            });
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 156,
                            child: subscribable
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: 1.25,
                                        child: Checkbox(
                                          value: checked,
                                          onChanged: (value) {
                                            Feedback.forTap(context);
                                            setDialogState(() {
                                              if (value == true) {
                                                checkedKeys.add(key);
                                              } else {
                                                checkedKeys.remove(key);
                                              }
                                            });
                                          },
                                          activeColor: const Color(0xFF22C55E),
                                          checkColor: Colors.white,
                                          side:
                                              WidgetStateBorderSide.resolveWith(
                                                  (states) {
                                            if (states.contains(
                                                WidgetState.selected)) {
                                              return const BorderSide(
                                                color: Colors.transparent,
                                                width: 0,
                                              );
                                            }

                                            return const BorderSide(
                                              color: Colors.white,
                                              width: 2,
                                            );
                                          }),
                                        ),
                                      ),
                                      Text(
                                        l.pickupEditNewNotification,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      '---',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePickupWithNotifications({
    required Set<String> checkedKeys,
    required BuildContext dialogContext,
  }) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final api = context.read<YouTubeApiService>();
    final pushProvider = context.read<PushSubscriptionProvider>();
    final pickupSettings = context.read<PickupSettingsProvider>();
    final dialogNavigator = Navigator.of(dialogContext);
    final pageNavigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saveFailedMessage =
        AppLocalizations.of(context)!.pickupEditSaveFailed;

    try {
      await _saveSelectedItems(checkedKeys: checkedKeys);

      final token = await PushTokenStore.getToken();

      final nextPushItems = _selected.where((item) {
        if (!_isPushSubscribable(item)) return false;

        return checkedKeys.contains(_pushKeyOf(item));
      }).toList();

      if (token != null && token.isNotEmpty) {
        await api.replacePushSubscriptions(
          token: token,
          items: nextPushItems,
        );
      }

      if (!context.mounted) return;

      pushProvider.setEnabledKeys(
        nextPushItems.map(_pushKeyOf),
      );

      if (!context.mounted) return;

      pickupSettings.notifyChanged();

      dialogNavigator.pop();
      pageNavigator.pop(true);
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(saveFailedMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final region = context.watch<RegionProvider>().regionCode;
    final l = AppLocalizations.of(context)!;
    final groups = _getGenreGroups(region);
    final favoriteChannels = _buildFavoriteChannelItems(
      context.watch<FavoritesService>().items,
      region,
    );
    final categoryNameById = {
      for (final group in groups)
        for (final category in group.items) category.id: category.name,
    };
    final categoryOrderById = <int, int>{};
    var categoryOrder = 0;
    for (final group in groups) {
      for (final category in group.items) {
        categoryOrderById[category.id] = categoryOrder++;
      }
    }

    return Scaffold(
      // backgroundColor: theme.scaffoldBackgroundColor,
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // =================================================
            // Header
            // =================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8,
                4,
                8,
                0,
              ),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        l.pickupEditTitle,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // Title
            // =================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                12,
                14,
                10,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surface
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.pickupEditCurrentSelection,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _selected.map((item) {
                        return _buildChip(
                          item.title,
                          selected: true,
                          onTap: () => _toggle(item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // =================================================
            // Tab
            // =================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: SizedBox(
                height: 42,
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3,
                      color: theme.colorScheme.primary,
                    ),
                    insets: EdgeInsets.zero,
                  ),
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: l.pickupEditGenreTab),
                    Tab(text: l.pickupEditChannelTab),
                    Tab(text: l.pickupEditFavoriteTab),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // Content
            // =================================================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGenreSectionWrap(groups),
                  _channelsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildChannelSectionWrap(
                          _channels,
                          categoryNameById,
                          categoryOrderById,
                        ),
                  _buildFavoriteChannelSectionWrap(favoriteChannels),
                ],
              ),
            ),

            // =================================================
            // Bottom Action Bar
            // =================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          l.commonCancel,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_selected.isEmpty || _isSaving)
                            ? null
                            : () async {
                                if (_isSaving) return;

                                await _showPickupConfirmDialog();
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l.commonDone,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
