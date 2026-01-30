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
  final int id;
  final String name;
  final bool isOfficial;
  final String query;
  final Color? color;

  const GenreCategory({
    required this.id,
    required this.name,
    required this.isOfficial,
    required this.query,
    this.color,
  });
}
