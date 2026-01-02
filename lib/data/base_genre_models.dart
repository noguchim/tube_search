import 'package:flutter/material.dart';

/// グループ
class GenreGroup {
  final String groupId;
  final String name;
  final Color color;
  final IconData icon;
  final List<GenreCategory> items;

  const GenreGroup({
    required this.groupId,
    required this.name,
    required this.color,
    required this.icon,
    required this.items,
  });
}

/// カテゴリ
class GenreCategory {
  final int id; // 公式ID or 独自ID
  final String name; // 表示名（国別で差し替えOK）
  final bool isOfficial; // YouTube公式カテゴリ or 独自
  final String query; // 検索最適化用（国別で変えてOK）

  const GenreCategory({
    required this.id,
    required this.name,
    required this.isOfficial,
    required this.query,
  });
}
