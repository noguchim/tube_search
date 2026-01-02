import 'base_genre_models.dart';
import 'genre_groups_en.dart';
import 'genre_groups_ja.dart';

List<GenreGroup> getGenreGroupsForRegion(String regionCode) {
  switch (regionCode) {
    case 'JP':
      return genreGroupsJa; // ← JP専用ジャンル構成
    case 'US':
      return genreGroupsEn; // ← US専用ジャンル構成
    default:
      return genreGroupsEn; // fallback
  }
}
