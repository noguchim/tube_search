import 'package:flutter/material.dart';

import 'base_genre_models.dart';

const baseCategoryIdsEn = {
  'G01': 24,
  'G02': 26,
  'G03': 27,
  'G04': 17,
  'G05': 22,
};

const genreGroupsEn = <GenreGroup>[
  GenreGroup(
    groupId: "G01",
    name: "Entertainment",
    color: Color(0xFFE53935),
    icon: Icons.movie_filter,
    items: [
      GenreCategory(id: 10, name: "Music", isOfficial: true, query: "Music"),
      GenreCategory(id: 23, name: "Comedy", isOfficial: true, query: "Comedy"),
      GenreCategory(
          id: 24,
          name: "Entertainment",
          isOfficial: true,
          query: "Entertainment"),
      GenreCategory(id: 20, name: "Gaming", isOfficial: true, query: "Gaming"),
    ],
  ),
  GenreGroup(
    groupId: "G02",
    name: "Lifestyle",
    color: Color(0xFF1E88E5),
    icon: Icons.home_filled,
    items: [
      GenreCategory(
          id: 15,
          name: "Pets & Animals",
          isOfficial: true,
          query: "Pets Animals"),
      GenreCategory(
          id: 26,
          name: "How-to & Style",
          isOfficial: true,
          query: "Howto Style"),
      GenreCategory(
          id: 1201,
          name: "Family & Kids",
          isOfficial: false,
          query: "family kids"),
    ],
  ),
  GenreGroup(
    groupId: "G03",
    name: "Knowledge",
    color: Color(0xFF43A047),
    icon: Icons.psychology_alt,
    items: [
      GenreCategory(id: 25, name: "News", isOfficial: true, query: "News"),
      GenreCategory(
          id: 28,
          name: "Science & Technology",
          isOfficial: true,
          query: "technology science"),
    ],
  ),
  GenreGroup(
    groupId: "G04",
    name: "Sports",
    color: Color(0xFF8E24AA),
    icon: Icons.sports_soccer,
    items: [
      GenreCategory(
          id: 1401, name: "Baseball", isOfficial: false, query: "baseball"),
      GenreCategory(
          id: 1402, name: "Soccer", isOfficial: false, query: "soccer"),
      GenreCategory(
          id: 1405,
          name: "American Football",
          isOfficial: false,
          query: "nfl football"),
    ],
  ),
  GenreGroup(
    groupId: "G05",
    name: "Others",
    color: Color(0xFF455A64),
    icon: Icons.apps,
    items: [
      GenreCategory(
          id: 2,
          name: "Autos & Vehicles",
          isOfficial: true,
          query: "cars vehicle"),
      GenreCategory(
          id: 1501, name: "DIY", isOfficial: false, query: "DIY tutorial"),
    ],
  ),
];
