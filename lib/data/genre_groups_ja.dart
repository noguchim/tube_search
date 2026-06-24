import 'package:flutter/material.dart';

import 'base_genre_models.dart';

/// グループのベースカテゴリ（日本）
const baseCategoryIdsJa = {
  'G00': 10,
  'G01': 24,
  'G02': 26,
  'G03': 27,
  'G04': 17,
  'G05': 22,
};

/// ------------------------------------------------------------
/// 🎉 🎉 🎉 ここから実データ（日本向け）
/// ------------------------------------------------------------
const genreGroupsJa = <GenreGroup>[
  /// ✨ G_REC：おすすめ
  GenreGroup(
    groupId: "G_REC",
    name: "おすすめ",
    color: Color(0xFF3B82F6),
    icon: Icons.auto_awesome,
    items: [
      GenreCategory(
        id: -1,
        name: "おすすめ",
        isOfficial: false,
        query: "",
        color: Color(0xFF3B82F6),
      ),
    ],
  ),

  /// 🎵 G00：音楽（NEW）
  GenreGroup(
    groupId: "G00",
    name: "Music",
    color: Color(0xFF1E88E5),
    icon: Icons.library_music,
    items: [
      GenreCategory(
        id: 10,
        name: "トレンド音楽",
        isOfficial: false,
        query: "音楽",
        color: Color(0xFFE53935),
      ),
      // 🇯🇵 日本
      GenreCategory(
        id: 12,
        name: "メガヒット（日本）",
        isOfficial: false,
        query: "音楽",
        color: Color(0xFFFFB74D),
      ),
      // 🌍 世界
      GenreCategory(
        id: 13,
        name: "メガヒット（海外）",
        isOfficial: false,
        query: "音楽",
        color: Color(0xFF7E57C2),
      ),
    ],
  ),

  /// 🟥 G01：エンタメ
  GenreGroup(
    groupId: "G01",
    name: "エンタメ",
    color: Color(0xFFF4511E),
    icon: Icons.movie_filter,
    items: [
      GenreCategory(
        id: 1300,
        name: "#shorts",
        isOfficial: false,
        query: "shorts",
        color: Color(0xFF43A047),
      ),
      GenreCategory(
          id: 1101,
          name: "YouTuber",
          isOfficial: false,
          query: "ユーチューバー",
          color: Color(0xFFF4511E)),
      GenreCategory(
          id: 1102,
          name: "VTuber",
          isOfficial: false,
          query: "ブイチューバー",
          color: Color(0xFF1E88E5)),
      GenreCategory(
        id: 31,
        name: "アニメ",
        isOfficial: false,
        query: "アニメ",
        color: Color(0xFF7E57C2),
      ),
      GenreCategory(
          id: 20,
          name: "ゲーム",
          isOfficial: true,
          query: "ゲーム",
          color: Color(0xFF1976D2)),
      GenreCategory(
          id: 1104,
          name: "パチンコ",
          isOfficial: false,
          query: "パチンコ スマパチ",
          color: Color(0xFFFFB74D)),
      GenreCategory(
          id: 1105,
          name: "パチスロ",
          isOfficial: false,
          query: "パチスロ スマスロ",
          color: Color(0xFF26A69A)),
      GenreCategory(
        id: 23,
        name: "お笑い",
        isOfficial: true,
        query: "お笑い コメディ",
        color: Color(0xFFF4511E),
      )
    ],
  ),

  /// 🟦 G02：ライフスタイル
  GenreGroup(
    groupId: "G02",
    name: "ライフスタイル",
    color: Color(0xFF1E88E5),
    icon: Icons.home_filled,
    items: [
      GenreCategory(
          id: 37,
          name: "ファミリー・キッズ",
          isOfficial: false,
          query: "ファミリー キッズ",
          color: Color(0xFF81C784)),
      GenreCategory(
          id: 1202,
          name: "料理・グルメ",
          isOfficial: false,
          query: "料理 グルメ 食べ歩き",
          color: Color(0xFFFFB74D)),
      GenreCategory(
          id: 1204,
          name: "コスメ・ファッション",
          isOfficial: false,
          query: "コスメ ファッション おしゃれ",
          color: Color(0xFFEC407A)),
      GenreCategory(
          id: 15,
          name: "ペット & 動物",
          isOfficial: true,
          query: "ペット 動物",
          color: Color(0xFFAED581)),
      // GenreCategory(
      //     id: 26,
      //     name: "ハウツー & スタイル",
      //     isOfficial: true,
      //     query: "ハウツー Howto Style",
      //     color: Color(0xFF4DB6AC)),
    ],
  ),

  /// 🟩 G03：知識・教養
  GenreGroup(
    groupId: "G03",
    name: "知識・教養",
    color: Color(0xFF43A047),
    icon: Icons.psychology_alt,
    items: [
      GenreCategory(
          id: 25,
          name: "ニュース",
          isOfficial: true,
          query: "ニュース",
          color: Color(0xFF546E7A)),
      GenreCategory(
          id: 28,
          name: "科学 & 技術",
          isOfficial: true,
          query: "科学 技術",
          color: Color(0xFF26A69A)),
      GenreCategory(
          id: 30,
          name: "カルチャー",
          isOfficial: true,
          query: "カルチャー",
          color: Color(0xFF7E57C2)),
    ],
  ),

  /// 🟪 G04：スポーツ
  GenreGroup(
    groupId: "G04",
    name: "スポーツ",
    color: Color(0xFF8E24AA),
    icon: Icons.sports_soccer,
    items: [
      GenreCategory(
          id: 1401,
          name: "野球",
          isOfficial: false,
          query: "野球",
          color: Color(0xFF2E7D32)),
      GenreCategory(
          id: 1402,
          name: "サッカー",
          isOfficial: false,
          query: "サッカー soccer",
          color: Color(0xFF4DB6AC)),
      GenreCategory(
          id: 1403,
          name: "格闘技",
          isOfficial: false,
          query: "格闘技",
          color: Color(0xFFC62828)),
      GenreCategory(
          id: 1404,
          name: "eスポーツ",
          isOfficial: false,
          query: "eスポーツ",
          color: Color(0xFF1976D2)),
    ],
  ),

  /// ⬛ G05：その他
  GenreGroup(
    groupId: "G05",
    name: "その他",
    color: Color(0xFF455A64),
    icon: Icons.apps,
    items: [
      GenreCategory(
          id: 2,
          name: "自動車・乗り物",
          isOfficial: true,
          query: "自動車 乗り物",
          color: Color(0xFF546E7A)),
      GenreCategory(
          id: 1501,
          name: "DIY",
          isOfficial: false,
          query: "DIY 作り方",
          color: Color(0xFF8D6E63)),
    ],
  ),
];
