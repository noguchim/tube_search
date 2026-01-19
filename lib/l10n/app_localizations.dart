import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @navPopular.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get navPopular;

  /// No description provided for @navGenre.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get navGenre;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @popularTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get popularTitle;

  /// No description provided for @infoTrendingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trending on YouTube — {region} — updated {date}'**
  String infoTrendingUpdated(String region, String date);

  /// No description provided for @noVideosFound.
  ///
  /// In en, this message translates to:
  /// **'No videos found'**
  String get noVideosFound;

  /// No description provided for @genreScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular by Genre'**
  String get genreScreenTitle;

  /// No description provided for @genreSearchHeader.
  ///
  /// In en, this message translates to:
  /// **'Search videos'**
  String get genreSearchHeader;

  /// No description provided for @genreNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the network'**
  String get genreNetworkError;

  /// No description provided for @genreBrowseHeader.
  ///
  /// In en, this message translates to:
  /// **'Browse by category'**
  String get genreBrowseHeader;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon to add favorites!'**
  String get favoritesEmptyHint;

  /// No description provided for @favoritesTapHere.
  ///
  /// In en, this message translates to:
  /// **'Tap here!'**
  String get favoritesTapHere;

  /// No description provided for @favoritesRegisteredSuffix.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get favoritesRegisteredSuffix;

  /// No description provided for @favoritesCountMessage.
  ///
  /// In en, this message translates to:
  /// **'Favorites: {current} / {limit}'**
  String favoritesCountMessage(Object current, Object limit);

  /// No description provided for @favoriteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites?'**
  String get favoriteDeleteTitle;

  /// No description provided for @favoriteDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from your favorites?'**
  String favoriteDeleteMessage(Object title);

  /// No description provided for @favoriteDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get favoriteDeleteCancel;

  /// No description provided for @favoriteDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get favoriteDeleteConfirm;

  /// No description provided for @favoriteLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites limit'**
  String get favoriteLimitTitle;

  /// No description provided for @favoriteLimitPurchased.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 50 favorites.'**
  String get favoriteLimitPurchased;

  /// No description provided for @favoriteLimitNotPurchased.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the favorites limit.\nUpgrading lets you save more favorites.'**
  String get favoriteLimitNotPurchased;

  /// No description provided for @favoriteLimitClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get favoriteLimitClose;

  /// No description provided for @favoriteLimitUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Limit upgrade'**
  String get favoriteLimitUpgrade;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get update;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLabelSystem.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get settingsThemeLabelSystem;

  /// No description provided for @settingsThemeLabelLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLabelLight;

  /// No description provided for @settingsThemeLabelDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeLabelDark;

  /// No description provided for @settingsFavoriteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm when removing favorites'**
  String get settingsFavoriteDeleteTitle;

  /// No description provided for @settingsFavoriteDeleteOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsFavoriteDeleteOn;

  /// No description provided for @settingsFavoriteDeleteOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsFavoriteDeleteOff;

  /// No description provided for @settingsShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get settingsShop;

  /// No description provided for @settingsShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade features for a better experience!'**
  String get settingsShopSubtitle;

  /// No description provided for @settingsPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get settingsPolicies;

  /// No description provided for @settingsPoliciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy & Terms'**
  String get settingsPoliciesSubtitle;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTerms;

  /// No description provided for @networkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the network'**
  String get networkErrorTitle;

  /// No description provided for @networkErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get networkErrorDescription;

  /// No description provided for @networkErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get networkErrorRetry;

  /// No description provided for @shopTitleRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get shopTitleRemoveAds;

  /// No description provided for @shopDescRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Hide all advertisements'**
  String get shopDescRemoveAds;

  /// No description provided for @shopTitleLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit upgrade'**
  String get shopTitleLimit;

  /// No description provided for @shopDescLimit.
  ///
  /// In en, this message translates to:
  /// **'Greatly increases the limit for trending videos and favorites'**
  String get shopDescLimit;

  /// No description provided for @shopTitleAutoplay.
  ///
  /// In en, this message translates to:
  /// **'Auto play'**
  String get shopTitleAutoplay;

  /// No description provided for @shopDescAutoplay.
  ///
  /// In en, this message translates to:
  /// **'Automatically play videos one after another'**
  String get shopDescAutoplay;

  /// No description provided for @shopPurchasedRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Ads have been removed'**
  String get shopPurchasedRemoveAds;

  /// No description provided for @shopPurchasedLimit.
  ///
  /// In en, this message translates to:
  /// **'Limits have been upgraded'**
  String get shopPurchasedLimit;

  /// No description provided for @shopPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get shopPurchased;

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'{price}\n(Buy)'**
  String shopBuy(Object price);

  /// No description provided for @shopRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get shopRestore;

  /// No description provided for @shopLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load product information'**
  String get shopLoadFailed;

  /// No description provided for @shopRestoreAlready.
  ///
  /// In en, this message translates to:
  /// **'Your purchases are already restored'**
  String get shopRestoreAlready;

  /// No description provided for @shopRestoreNothing.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore'**
  String get shopRestoreNothing;

  /// No description provided for @shopRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get shopRestoreDone;

  /// No description provided for @settingsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settingsRegion;

  /// No description provided for @settingsRegionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the country for video trends'**
  String get settingsRegionSubtitle;

  /// No description provided for @regionJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get regionJapan;

  /// No description provided for @regionUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get regionUnitedStates;

  /// No description provided for @regionUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get regionUnitedKingdom;

  /// No description provided for @regionGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get regionGermany;

  /// No description provided for @regionFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get regionFrance;

  /// No description provided for @regionIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get regionIndia;

  /// No description provided for @repeatStatusOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get repeatStatusOff;

  /// No description provided for @repeatStatusAscending.
  ///
  /// In en, this message translates to:
  /// **'ON (Ascending)'**
  String get repeatStatusAscending;

  /// No description provided for @repeatStatusDescending.
  ///
  /// In en, this message translates to:
  /// **'ON (Descending)'**
  String get repeatStatusDescending;

  /// No description provided for @repeatStatusRandom.
  ///
  /// In en, this message translates to:
  /// **'ON (Random)'**
  String get repeatStatusRandom;

  /// No description provided for @repeatDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Continuous play settings'**
  String get repeatDialogTitle;

  /// No description provided for @repeatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Continuous play settings'**
  String get repeatSettingsTitle;

  /// No description provided for @repeatOptionOff.
  ///
  /// In en, this message translates to:
  /// **'OFF (do not auto-play)'**
  String get repeatOptionOff;

  /// No description provided for @repeatOptionAscending.
  ///
  /// In en, this message translates to:
  /// **'Play in ascending order'**
  String get repeatOptionAscending;

  /// No description provided for @repeatOptionDescending.
  ///
  /// In en, this message translates to:
  /// **'Play in descending order'**
  String get repeatOptionDescending;

  /// No description provided for @repeatOptionRandom.
  ///
  /// In en, this message translates to:
  /// **'Shuffle play'**
  String get repeatOptionRandom;

  /// No description provided for @repeatDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get repeatDialogCancel;

  /// No description provided for @repeatDialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get repeatDialogSave;

  /// No description provided for @repeatDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Select how continuous play should behave.'**
  String get repeatDialogMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
