import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/pickup_edit_screen.dart';

import '../data/pickup_selectable_item.dart';
import '../l10n/app_localizations.dart';
import '../providers/push_subscription_provider.dart';
import '../services/push_token_store.dart';
import '../services/youtube_api_service.dart';
import '../widgets/app_back_button.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  bool _trendPushEnabled = true;
  List<PickupSelectableItem> _pickupItems = [];
  bool _didLoadPickupItems = false;
  bool _hasCustomPickupItems = false;
  static const String _pickupSelectedPrefsKey = 'pickup_selected_items';
  static const String _pickupPushDefaultsSignaturePrefsKey =
      'pickup_push_defaults_signature';
  static const Color _notificationAccentColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadPickupItems) return;
    _didLoadPickupItems = true;
    _loadPickupPushItems();
  }

  Future<void> _loadPickupPushItems() async {
    final l = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSelectedPrefsKey);

    // まだピックアップ編集していない場合
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasCustomPickupItems = false;
        _pickupItems = _defaultPickupItems(l);
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return;

      final items = decoded
          .map<PickupSelectableItem>((e) {
            final json = Map<String, dynamic>.from(e as Map);

            final type = json['type'] == PickupTargetType.channel.name
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
            );
          })
          .where((item) {
            return item.key.isNotEmpty && item.title.isNotEmpty;
          })
          .toList();

      if (!mounted) return;

      setState(() {
        _hasCustomPickupItems = items.isNotEmpty;
        _pickupItems = items;
      });

      await _initializeCustomPickupPushDefaultsIfNeeded(
        prefs: prefs,
        items: items,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasCustomPickupItems = false;
        _pickupItems = _defaultPickupItems(l);
      });
    }
  }

  List<PickupSelectableItem> _defaultPickupItems(AppLocalizations l) {
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

  String _pickupSignature(List<PickupSelectableItem> items) {
    final keys = items.map((item) => item.key).toList()..sort();
    return keys.join('|');
  }

  Future<void> _initializeCustomPickupPushDefaultsIfNeeded({
    required SharedPreferences prefs,
    required List<PickupSelectableItem> items,
  }) async {
    if (items.isEmpty) return;

    final signature = _pickupSignature(items);
    final initializedSignature = prefs.getString(
      _pickupPushDefaultsSignaturePrefsKey,
    );

    if (initializedSignature == signature) return;

    final enabledItems = items.where(_isPushSubscribable).toList();
    if (enabledItems.isEmpty) return;

    if (!mounted) return;

    context.read<PushSubscriptionProvider>().setEnabledKeys(
      enabledItems.map(_pushKeyOf),
    );

    await prefs.setString(_pickupPushDefaultsSignaturePrefsKey, signature);

    final token = await PushTokenStore.getToken();
    if (token == null || token.isEmpty) return;

    if (!mounted) return;

    final api = context.read<YouTubeApiService>();
    try {
      await api.replacePushSubscriptions(token: token, items: enabledItems);
    } catch (_) {
      // 表示初期化は維持し、個別スイッチ操作時の保存で再同期する。
    }
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    String? subtitle,
    VoidCallback? onSubtitleLinkTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              if (onSubtitleLinkTap == null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              // else
              //   Text.rich(
              //     TextSpan(
              //       style: TextStyle(
              //         fontSize: 12,
              //         height: 1.4,
              //         color:
              //             theme.colorScheme.onSurface.withValues(alpha: 0.62),
              //       ),
              //       children: [
              //         const TextSpan(text: "ピックアップの項目ごとに新着動画を通知します。"),
              //         TextSpan(
              //           text: "ピックアップの編集",
              //           style: TextStyle(
              //             color: theme.colorScheme.primary,
              //             fontWeight: FontWeight.w700,
              //             decoration: TextDecoration.underline,
              //           ),
              //           recognizer: TapGestureRecognizer()
              //             ..onTap = onSubtitleLinkTap,
              //         ),
              //         const TextSpan(
              //           text: "から新しい項目が設定されていなかった場合、通知は行われません",
              //         ),
              //       ],
              //     ),
              //   ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? subtitle,
    bool dimDisabledTitle = true,
  }) {
    final theme = Theme.of(context);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _notificationAccentColor;
        }

        if (states.contains(WidgetState.disabled)) {
          return theme.colorScheme.onSurface.withValues(alpha: 0.28);
        }

        return theme.colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _notificationAccentColor.withValues(alpha: 0.32);
        }

        if (states.contains(WidgetState.disabled)) {
          return theme.colorScheme.onSurface.withValues(alpha: 0.12);
        }

        return theme.colorScheme.surfaceContainerHighest;
      }),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onChanged == null && dimDisabledTitle
              ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
    );
  }

  Future<void> _updateTrendPushEnabled(bool enabled) async {
    final api = context.read<YouTubeApiService>();
    final messenger = ScaffoldMessenger.of(context);
    final updateFailedMessage = AppLocalizations.of(
      context,
    )!.pushSettingsUpdateFailed;

    try {
      final token = await PushTokenStore.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("FCM token not found");
      }

      await api.updatePushStatus(token: token, enabled: enabled);

      if (!mounted) return;

      setState(() {
        _trendPushEnabled = enabled;
      });
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(updateFailedMessage)));
    }
  }

  Future<void> _updatePickupPushEnabled(
    PickupSelectableItem target,
    bool enabled,
  ) async {
    if (!_isPushSubscribable(target)) return;

    final api = context.read<YouTubeApiService>();
    final messenger = ScaffoldMessenger.of(context);
    final updateFailedMessage = AppLocalizations.of(
      context,
    )!.pushSettingsUpdateFailed;
    final pushProvider = context.read<PushSubscriptionProvider>();

    final nextKeys = Set<String>.from(pushProvider.enabledKeys);
    final targetKey = _pushKeyOf(target);

    if (targetKey.isEmpty) return;

    if (enabled) {
      nextKeys.add(targetKey);
    } else {
      nextKeys.remove(targetKey);
    }

    final enabledItems = _pickupItems.where((item) {
      return nextKeys.contains(_pushKeyOf(item));
    }).toList();

    try {
      final token = await PushTokenStore.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("FCM token not found");
      }

      await api.replacePushSubscriptions(token: token, items: enabledItems);

      if (!mounted) return;

      context.read<PushSubscriptionProvider>().setEnabledKeys(
        enabledItems.map(_pushKeyOf),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(updateFailedMessage)));
    }
  }

  String _pushKeyOf(PickupSelectableItem item) {
    if (item.type == PickupTargetType.channel) {
      final channelId = item.channelId ?? '';
      return channelId.isEmpty ? '' : 'channel:$channelId';
    }

    final categoryId = item.categoryId;
    return categoryId == null ? '' : 'category:$categoryId';
  }

  Widget _buildPickupPushSectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pushPickupSectionTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              children: [
                TextSpan(text: l.pushPickupDescription),
                if (!_hasCustomPickupItems) ...[
                  TextSpan(text: l.pushPickupInitialWarningPrefix),
                  TextSpan(
                    text: l.pushPickupEditLink,
                    style: const TextStyle(
                      color: _notificationAccentColor,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PickupEditScreen(),
                          ),
                        );

                        if (!mounted) return;

                        if (changed == true) {
                          await _loadPickupPushItems();
                        }
                      },
                  ),
                  TextSpan(text: l.pushPickupInitialWarningSuffix),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pushSubs = context.watch<PushSubscriptionProvider>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        l.pushSettingsTitle,
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildSectionTitle(
                    context,
                    l.pushTrendingSectionTitle,
                    subtitle: l.pushTrendingSectionSubtitle,
                  ),
                  _buildSwitchTile(
                    title: l.pushTrendingTitle,
                    value: _trendPushEnabled,
                    onChanged: (value) {
                      _updateTrendPushEnabled(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPickupPushSectionTitle(context),
                  ..._pickupItems.map((item) {
                    final canSubscribe = _isPushSubscribable(item);

                    final enabled = canSubscribe
                        ? pushSubs.isEnabled(_pushKeyOf(item))
                        : false;

                    return _buildSwitchTile(
                      title: item.title,
                      value: enabled,
                      subtitle: canSubscribe ? null : l.pushItemNotSubscribable,
                      dimDisabledTitle: canSubscribe,
                      onChanged: canSubscribe
                          ? (value) {
                              _updatePickupPushEnabled(item, value);
                            }
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
