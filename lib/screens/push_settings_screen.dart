import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/screens/pickup_edit_screen.dart';

import '../data/pickup_selectable_item.dart';
import '../providers/push_subscription_provider.dart';
import '../services/push_token_store.dart';
import '../services/youtube_api_service.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  bool _trendPushEnabled = true;
  List<PickupSelectableItem> _pickupItems = [];
  bool _pickupSwitchEnabled = false;
  static const String _pickupSelectedPrefsKey = 'pickup_selected_items';
  static const Color _notificationAccentColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadPickupPushItems();
  }

  Future<void> _loadPickupPushItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupSelectedPrefsKey);

    // まだピックアップ編集していない場合
    if (raw == null || raw.isEmpty) {
      setState(() {
        _pickupSwitchEnabled = true;
        _pickupItems = const [
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
      });
      return;
    }

    final decoded = jsonDecode(raw);

    final items = (decoded as List).map<PickupSelectableItem>((e) {
      final json = Map<String, dynamic>.from(e as Map);

      final type = json['type'] == PickupTargetType.channel.name
          ? PickupTargetType.channel
          : PickupTargetType.category;

      return PickupSelectableItem(
        type: type,
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        channelId: json['channelId']?.toString(),
        categoryId: int.tryParse('${json['categoryId'] ?? ''}'),
      );
    }).where((item) {
      return item.key.isNotEmpty && item.title.isNotEmpty;
    }).toList();

    setState(() {
      _pickupSwitchEnabled = true;
      _pickupItems = items;
    });
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
                )
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
    try {
      final token = await PushTokenStore.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("FCM token not found");
      }

      final api = context.read<YouTubeApiService>();

      await api.updatePushStatus(
        token: token,
        enabled: enabled,
      );

      if (!mounted) return;

      setState(() {
        _trendPushEnabled = enabled;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("通知設定を更新できませんでした"),
        ),
      );
    }
  }

  Future<void> _updatePickupPushEnabled(
    PickupSelectableItem target,
    bool enabled,
  ) async {
    if (!_isPushSubscribable(target)) return;

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

      final api = context.read<YouTubeApiService>();

      await api.replacePushSubscriptions(
        token: token,
        items: enabledItems,
      );

      if (!mounted) return;

      context.read<PushSubscriptionProvider>().setEnabledKeys(
            enabledItems.map(_pushKeyOf),
          );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("通知設定を更新できませんでした"),
        ),
      );
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ピックアップの通知",
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
                const TextSpan(
                  text: "ピックアップ項目ごとに新着動画を通知します。",
                ),
                if (!_pickupSwitchEnabled) ...[
                  const TextSpan(
                    text: "ピックアップ項目が初期状態の場合は通知は行われません。通知を行う場合は",
                  ),
                  TextSpan(
                    text: "ピックアップ編集",
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
                  const TextSpan(
                    text: "でピックアップ項目の編集を行ってください。",
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isPushSubscribable(PickupSelectableItem item) {
    if (item.key == 'category:all') return false;

    if (item.type == PickupTargetType.channel) {
      return item.channelId != null && item.channelId!.isNotEmpty;
    }

    return item.categoryId != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pushSubs = context.watch<PushSubscriptionProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
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
                    const Center(
                      child: Text(
                        "プッシュ通知の設定",
                        style: TextStyle(
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
                    "人気動画の通知",
                    subtitle: "急上昇動画を通知します。",
                  ),
                  _buildSwitchTile(
                    title: "人気急上昇",
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
                      subtitle: canSubscribe ? null : "この項目は通知対象外です",
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
