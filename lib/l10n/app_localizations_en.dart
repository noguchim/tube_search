// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navPopular => 'Trending';

  @override
  String get navGenre => 'Genres';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSettings => 'Settings';

  @override
  String get popularTitle => 'Trending Now';

  @override
  String infoTrendingUpdated(String region, String date) {
    return 'Trending on YouTube — $region — updated $date';
  }

  @override
  String get noVideosFound => 'No videos found';

  @override
  String get genreScreenTitle => 'Popular by Genre';

  @override
  String get genreSearchHeader => 'Search videos';

  @override
  String get genreSearchHint => 'Type a keyword...';

  @override
  String get genreNetworkError => 'Cannot connect to the network';

  @override
  String get genreBrowseHeader => 'Browse by category';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyHint => 'Tap the heart icon to add favorites!';

  @override
  String get favoritesTapHere => 'Tap here!';

  @override
  String get favoritesRegisteredSuffix => 'saved';

  @override
  String favoritesCountMessage(Object current, Object limit) {
    return 'Favorites: $current / $limit';
  }

  @override
  String get favoriteDeleteTitle => 'Remove from favorites?';

  @override
  String favoriteDeleteMessage(Object title) {
    return 'Remove \"$title\" from your favorites?';
  }

  @override
  String get favoriteDeleteCancel => 'Cancel';

  @override
  String get favoriteDeleteConfirm => 'Remove';

  @override
  String get favoriteLimitTitle => 'Favorites limit';

  @override
  String get favoriteLimitPurchased => 'You can save up to 50 favorites.';

  @override
  String get favoriteLimitNotPurchased =>
      'You can save up to 10 favorites.\n\nA limit upgrade allows up to 5× (50 items).';

  @override
  String get favoriteLimitClose => 'Close';

  @override
  String get favoriteLimitUpgrade => 'Limit upgrade';

  @override
  String genrePopularTitle(Object genre) {
    return 'Trending: $genre';
  }

  @override
  String get update => 'updated';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Use device setting';

  @override
  String get settingsThemeLight => 'Light mode';

  @override
  String get settingsThemeDark => 'Dark mode';

  @override
  String get settingsThemeLabelSystem => 'Device default';

  @override
  String get settingsThemeLabelLight => 'Light';

  @override
  String get settingsThemeLabelDark => 'Dark';

  @override
  String get settingsFavoriteDeleteTitle => 'Confirm when removing favorites';

  @override
  String get settingsFavoriteDeleteOn => 'On';

  @override
  String get settingsFavoriteDeleteOff => 'Off';

  @override
  String get settingsShop => 'Shop';

  @override
  String get settingsShopSubtitle =>
      'Upgrade features for a better experience!';

  @override
  String get settingsPolicies => 'Policies';

  @override
  String get settingsPoliciesSubtitle => 'Privacy policy & Terms';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get networkErrorTitle => 'Cannot connect to the network';

  @override
  String get networkErrorDescription =>
      'Please check your connection and try again.';

  @override
  String get networkErrorRetry => 'Retry';

  @override
  String get shopTitleRemoveAds => 'Remove ads';

  @override
  String get shopDescRemoveAds => 'Hide all advertisements';

  @override
  String get shopTitleLimit => 'Limit upgrade';

  @override
  String get shopDescLimit =>
      'Greatly increases the limit for trending videos and favorites';

  @override
  String get shopTitleAutoplay => 'Auto play';

  @override
  String get shopDescAutoplay => 'Automatically play videos one after another';

  @override
  String get shopPurchasedRemoveAds => 'Ads have been removed';

  @override
  String get shopPurchasedLimit => 'Limits have been upgraded';

  @override
  String get shopPurchased => 'Purchased';

  @override
  String shopBuy(Object price) {
    return '$price\n(Buy)';
  }

  @override
  String get shopRestore => 'Restore purchases';

  @override
  String get shopLoadFailed => 'Failed to load product information';

  @override
  String get shopRestoreAlready => 'Your purchases are already restored';

  @override
  String get shopRestoreNothing => 'No purchases to restore';

  @override
  String get shopRestoreDone => 'Purchases restored';

  @override
  String get settingsRegion => 'Region';

  @override
  String get settingsRegionSubtitle => 'Choose the country for video trends';

  @override
  String get regionJapan => 'Japan';

  @override
  String get regionUnitedStates => 'United States';
}
