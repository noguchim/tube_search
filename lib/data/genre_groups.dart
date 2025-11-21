import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// 🎯 グループモデル
/// ------------------------------------------------------------
class GenreGroup {
  final String groupId; // G01〜
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

/// ------------------------------------------------------------
/// 🎯 カテゴリモデル
/// ------------------------------------------------------------
class GenreCategory {
  final int id; // 公式ID or 独自ID（1101〜）
  final String name;
  final bool isOfficial;
  final String query; // API検索最適化用

  const GenreCategory({
    required this.id,
    required this.name,
    required this.isOfficial,
    required this.query,
  });
}

/// グループのベースとなる YouTube 公式カテゴリID（検索用）
const baseCategoryIds = {
  'G01': 24, // エンタメ
  'G02': 26, // ライフスタイル
  'G03': 27, // 知識・教養
  'G04': 17, // スポーツ
  'G05': 22, // その他
};

/// ------------------------------------------------------------
/// 🎉 🎉 🎉 ここから実データ（あなた専用カスタム）
/// ------------------------------------------------------------

const genreGroups = <GenreGroup>[
  /// ==========================================================
  /// 🟥 G01：エンタメ
  /// ==========================================================
  GenreGroup(
    groupId: "G01",
    name: "エンタメ",
    color: Color(0xFFE53935),
    icon: Icons.movie_filter,
    items: [
      GenreCategory(id: 1101, name: "アニメ", isOfficial: false, query: "アニメ"),
      GenreCategory(id: 1102, name: "VTuber", isOfficial: false, query: "VTuber"),
      GenreCategory(id: 10, name: "音楽", isOfficial: true, query: "Music"),
      GenreCategory(id: 20, name: "ゲーム", isOfficial: true, query: "Game"),
      GenreCategory(id: 1103, name: "パチンコ", isOfficial: false, query: "パチンコ"),
      GenreCategory(id: 1104, name: "パチスロ", isOfficial: false, query: "パチスロ"),
      GenreCategory(id: 24, name: "エンターテイメント", isOfficial: true, query: "Entertainment"),
      GenreCategory(id: 23, name: "コメディ", isOfficial: true, query: "Comedy"),
    ],
  ),

  /// ==========================================================
  /// 🟦 G02：ライフスタイル
  /// ==========================================================
  GenreGroup(
    groupId: "G02",
    name: "ライフスタイル",
    color: Color(0xFF1E88E5),
    icon: Icons.home_filled,
    items: [
      GenreCategory(id: 1201, name: "ファミリー・キッズ", isOfficial: false, query: "ファミリー キッズ"),
      GenreCategory(id: 1202, name: "料理・グルメ", isOfficial: false, query: "料理 グルメ 食べ歩き"),
      GenreCategory(id: 1203, name: "美容", isOfficial: false, query: "美容"),
      GenreCategory(id: 1204, name: "ファッション", isOfficial: false, query: "ファッション"),
      GenreCategory(id: 15, name: "ペット & 動物", isOfficial: true, query: "Pets Animals"),
      GenreCategory(id: 26, name: "ハウツー & スタイル", isOfficial: true, query: "Howto Style"),
    ],
  ),

  /// ==========================================================
  /// 🟩 G03：知識 / 教養 / 教育
  /// ==========================================================
  GenreGroup(
    groupId: "G03",
    name: "知識・教養",
    color: Color(0xFF43A047),
    icon: Icons.psychology_alt,
    items: [
      GenreCategory(id: 25, name: "ニュース", isOfficial: true, query: "News"),
      GenreCategory(id: 28, name: "科学 & 技術", isOfficial: true, query: "科学 技術"),
    ],
  ),

  /// ==========================================================
  /// 🟪 G04：スポーツ
  /// ==========================================================
  GenreGroup(
    groupId: "G04",
    name: "スポーツ",
    color: Color(0xFF8E24AA),
    icon: Icons.sports_soccer,
    items: [
      GenreCategory(id: 1401, name: "野球", isOfficial: false, query: "野球"),
      GenreCategory(id: 1402, name: "サッカー", isOfficial: false, query: "サッカー"),
      GenreCategory(id: 1403, name: "格闘技", isOfficial: false, query: "格闘技"),
      GenreCategory(id: 1404, name: "eスポーツ", isOfficial: false, query: "eスポーツ"),
    ],
  ),

  /// ==========================================================
  /// ⬛ G05：その他
  /// ==========================================================
  GenreGroup(
    groupId: "G05",
    name: "その他",
    color: Color(0xFF455A64),
    icon: Icons.apps,
    items: [
      GenreCategory(id: 2, name: "自動車・乗り物", isOfficial: true, query: "自動車 乗り物"),
      GenreCategory(id: 1501, name: "DIY", isOfficial: false, query: "DIY 作り方"),
    ],
  ),
];
