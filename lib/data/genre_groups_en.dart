import 'package:flutter/material.dart';

import 'base_genre_models.dart';

const baseCategoryIdsEn = {
  'G01': 24,
  'G02': 26,
  'G03': 27,
  'G04': 17,
  'G05': 22,
};
//
//アメリカリリース時は中身を調整
//
const genreGroupsEn = <GenreGroup>[
  /// 🟥 G01：エンタメ
  GenreGroup(
    groupId: "G01",
    name: "エンタメ",
    color: Color(0xFFE53935),
    icon: Icons.movie_filter,
    items: [
      GenreCategory(
        id: 10,
        name: "音楽",
        isOfficial: true,
        query: "Music",
        color: Color(0xFFD32F2F),
      ),
      GenreCategory(
          id: 1101,
          name: "ユーチューバー",
          isOfficial: false,
          query: "ユーチューバー",
          color: Color(0xFFF4511E)),
      GenreCategory(
          id: 1102,
          name: "Vチューバー",
          isOfficial: false,
          query: "Vチューバー",
          color: Color(0xFFF4511E)),
      GenreCategory(
        id: 1103,
        name: "アニメ",
        isOfficial: false,
        query: "アニメ",
        color: Color(0xFF7E57C2),
      ),
      GenreCategory(
          id: 20,
          name: "ゲーム",
          isOfficial: true,
          query: "Game",
          color: Color(0xFF7E57C2)),
      GenreCategory(
          id: 1104,
          name: "パチンコ",
          isOfficial: false,
          query: "パチンコ",
          color: Color(0xFF455A64)),
      GenreCategory(
          id: 1105,
          name: "パチスロ",
          isOfficial: false,
          query: "パチスロ",
          color: Color(0xFF455A64)),
      GenreCategory(
          id: 24,
          name: "エンターテイメント",
          isOfficial: true,
          query: "Entertainment",
          color: Color(0xFFD32F2F)),
      GenreCategory(
          id: 23,
          name: "コメディ",
          isOfficial: true,
          query: "Comedy",
          color: Color(0xFFF4511E)),
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
          id: 1201,
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
          id: 1203,
          name: "美容",
          isOfficial: false,
          query: "美容",
          color: Color(0xFFEC407A)),
      GenreCategory(
          id: 1204,
          name: "ファッション",
          isOfficial: false,
          query: "ファッション",
          color: Color(0xFFEC407A)),
      GenreCategory(
          id: 15,
          name: "ペット & 動物",
          isOfficial: true,
          query: "Pets Animals",
          color: Color(0xFFAED581)),
      GenreCategory(
          id: 26,
          name: "ハウツー & スタイル",
          isOfficial: true,
          query: "Howto Style",
          color: Color(0xFF4DB6AC)),
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
          query: "News",
          color: Color(0xFF546E7A)),
      GenreCategory(
          id: 28,
          name: "科学 & 技術",
          isOfficial: true,
          query: "科学 技術",
          color: Color(0xFF26A69A)),
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
          query: "サッカー",
          color: Color(0xFF2E7D32)),
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
