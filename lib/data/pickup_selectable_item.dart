import 'package:flutter/material.dart';

import 'base_genre_models.dart';

enum PickupTargetType {
  category,
  channel,
}

class PickupSelectableItem {
  final PickupTargetType type;

  /// UI・保存・比較用の一意キー
  /// 例: category:10 / channel:UCxxxx
  final String key;

  /// 表示名
  final String title;

  /// 補助表示
  /// 例: Music / にじさんじ / JP
  final String? subtitle;

  /// API保存用
  /// categoryなら categoryId、channelなら channelId
  final int? categoryId;
  final String? channelId;

  /// 検索・API用補助
  final String? query;
  final String? region;

  /// UI装飾
  final Color? color;
  final IconData? icon;

  final int priority;
  final bool pushEnabled;

  const PickupSelectableItem({
    required this.type,
    required this.key,
    required this.title,
    this.subtitle,
    this.categoryId,
    this.channelId,
    this.query,
    this.region,
    this.color,
    this.icon,
    this.priority = 0,
    this.pushEnabled = false,
  });

  factory PickupSelectableItem.fromCategory({
    required GenreGroup group,
    required GenreCategory category,
  }) {
    return PickupSelectableItem(
      type: PickupTargetType.category,
      key: 'category:${category.id}',
      title: category.name,
      subtitle: group.name,
      categoryId: category.id,
      query: category.query,
      color: category.color,
      icon: group.icon,
      priority: 0,
      pushEnabled: true,
    );
  }

  factory PickupSelectableItem.fromChannel({
    required String channelId,
    required String channelTitle,
    String? groupName,
    int? categoryId,
    String? region,
    int priority = 0,
  }) {
    return PickupSelectableItem(
      type: PickupTargetType.channel,
      key: 'channel:$channelId',
      title: channelTitle,
      subtitle: groupName,
      channelId: channelId,
      categoryId: categoryId,
      region: region,
      priority: priority,
      icon: Icons.account_circle,
      pushEnabled: true,
    );
  }
}

class PickupItemSection {
  final String title;
  final List<PickupSelectableItem> items;

  const PickupItemSection({
    required this.title,
    required this.items,
  });
}
