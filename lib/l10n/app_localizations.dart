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
    Locale('ja'),
  ];

  /// No description provided for @newPickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Picks'**
  String get newPickupTitle;

  /// No description provided for @navPopular.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get navPopular;

  /// No description provided for @navTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get navTopic;

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

  /// No description provided for @noVideosFound.
  ///
  /// In en, this message translates to:
  /// **'No videos were found'**
  String get noVideosFound;

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

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon to add favorites!'**
  String get favoritesEmptyHint;

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

  /// No description provided for @settingsShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get settingsShop;

  /// No description provided for @settingsShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More features'**
  String get settingsShopSubtitle;

  /// No description provided for @settingsPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get settingsPolicies;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @aboutRankingCalculation.
  ///
  /// In en, this message translates to:
  /// **'How Rankings Are Calculated'**
  String get aboutRankingCalculation;

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

  /// No description provided for @shopTitleContinueWatchPro.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching Pro'**
  String get shopTitleContinueWatchPro;

  /// No description provided for @shopDescContinueWatchPro.
  ///
  /// In en, this message translates to:
  /// **'Expand saved playlists from 10 to 30'**
  String get shopDescContinueWatchPro;

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

  /// No description provided for @shopPurchasedContinueWatchPro.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching Pro is now active'**
  String get shopPurchasedContinueWatchPro;

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

  /// No description provided for @favoriteLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This video is locked'**
  String get favoriteLockedTitle;

  /// No description provided for @favoriteLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This video is currently locked.\nUnlock it to remove from favorites.'**
  String get favoriteLockedMessage;

  /// No description provided for @favoriteUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this video?'**
  String get favoriteUnlockTitle;

  /// No description provided for @favoriteUnlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlocking this video will allow it to be removed from favorites.'**
  String get favoriteUnlockMessage;

  /// No description provided for @favoriteUnlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get favoriteUnlockConfirm;

  /// No description provided for @favoriteUnlockCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get favoriteUnlockCancel;

  /// No description provided for @favoriteLock.
  ///
  /// In en, this message translates to:
  /// **'lock'**
  String get favoriteLock;

  /// No description provided for @favoriteDelete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get favoriteDelete;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest version is now available.'**
  String get updateAvailableMessage;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @buttonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOk;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About this App'**
  String get settingsAbout;

  /// No description provided for @browserOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open the browser'**
  String get browserOpenFailed;

  /// No description provided for @updateNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Notice'**
  String get updateNoticeTitle;

  /// No description provided for @appUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'The app has been updated to the latest version'**
  String get appUpdatedMessage;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @trendWords.
  ///
  /// In en, this message translates to:
  /// **'Trending Words'**
  String get trendWords;

  /// No description provided for @commonGame.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get commonGame;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @relatedVideos.
  ///
  /// In en, this message translates to:
  /// **'Related videos'**
  String get relatedVideos;

  /// No description provided for @pickupRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get pickupRecommended;

  /// No description provided for @pickupTrendMusic.
  ///
  /// In en, this message translates to:
  /// **'Trending music'**
  String get pickupTrendMusic;

  /// No description provided for @pushSettingsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pushSettingsMenuTitle;

  /// No description provided for @pushSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get pushSettingsTitle;

  /// No description provided for @pushSettingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update notification settings'**
  String get pushSettingsUpdateFailed;

  /// No description provided for @pushPickupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick-up notifications'**
  String get pushPickupSectionTitle;

  /// No description provided for @pushPickupDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notifications for new videos for each pick-up item.'**
  String get pushPickupDescription;

  /// No description provided for @pushPickupInitialWarningPrefix.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not sent while pick-ups are still at their default settings. To enable them, edit your items in '**
  String get pushPickupInitialWarningPrefix;

  /// No description provided for @pushPickupEditLink.
  ///
  /// In en, this message translates to:
  /// **'Edit pick-ups'**
  String get pushPickupEditLink;

  /// No description provided for @pushPickupInitialWarningSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get pushPickupInitialWarningSuffix;

  /// No description provided for @pushTrendingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast-Rising Video Notifications'**
  String get pushTrendingSectionTitle;

  /// No description provided for @pushTrendingSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about videos that are quickly gaining views after being posted.'**
  String get pushTrendingSectionSubtitle;

  /// No description provided for @pushTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast-Rising'**
  String get pushTrendingTitle;

  /// No description provided for @pushItemNotSubscribable.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not available for this item'**
  String get pushItemNotSubscribable;

  /// No description provided for @pickupEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit pick-ups'**
  String get pickupEditTitle;

  /// No description provided for @pickupEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change pick-ups'**
  String get pickupEditDialogTitle;

  /// No description provided for @pickupEditDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Set your pick-ups as shown below.'**
  String get pickupEditDialogMessage;

  /// No description provided for @pickupEditCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current selection'**
  String get pickupEditCurrentSelection;

  /// No description provided for @pickupEditGenreTab.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get pickupEditGenreTab;

  /// No description provided for @pickupEditChannelTab.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get pickupEditChannelTab;

  /// No description provided for @pickupEditFavoriteTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get pickupEditFavoriteTab;

  /// No description provided for @pickupEditFavoriteEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get pickupEditFavoriteEmptyTitle;

  /// No description provided for @pickupEditFavoriteEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When you add favorite videos, their channels will appear here.'**
  String get pickupEditFavoriteEmptyMessage;

  /// No description provided for @pickupEditNewNotification.
  ///
  /// In en, this message translates to:
  /// **'New video notifications'**
  String get pickupEditNewNotification;

  /// No description provided for @pickupEditSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get pickupEditSaveFailed;

  /// No description provided for @pickupEditCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Category {categoryId}'**
  String pickupEditCategoryFallback(Object categoryId);

  /// No description provided for @topicPickupEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit pick-ups'**
  String get topicPickupEditTitle;

  /// No description provided for @topicPickupEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the button at the bottom right to customize your pick-ups by genre or channel.'**
  String get topicPickupEditMessage;

  /// No description provided for @pickupEmptyNewVideos.
  ///
  /// In en, this message translates to:
  /// **'No new videos yet'**
  String get pickupEmptyNewVideos;

  /// No description provided for @watchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch history'**
  String get watchHistoryTitle;

  /// No description provided for @watchHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No watch history yet'**
  String get watchHistoryEmpty;

  /// No description provided for @videoPlayerOpenYoutubeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube'**
  String get videoPlayerOpenYoutubeTooltip;

  /// No description provided for @videoPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Playing on YouTube'**
  String get videoPlayerTitle;

  /// No description provided for @videoPlayerDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap Open to view the video page.'**
  String get videoPlayerDescription;

  /// No description provided for @videoPlayerOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get videoPlayerOpening;

  /// No description provided for @videoPlayerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get videoPlayerOpen;

  /// No description provided for @settingsConfirmDeleteEnabled.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirmDeleteEnabled;

  /// No description provided for @settingsConfirmDeleteDisabled.
  ///
  /// In en, this message translates to:
  /// **'Do not confirm'**
  String get settingsConfirmDeleteDisabled;

  /// No description provided for @topBarSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get topBarSortTooltip;

  /// No description provided for @sortByScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get sortByScore;

  /// No description provided for @sortByViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get sortByViews;

  /// No description provided for @sortByNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortByNewest;

  /// No description provided for @publishedSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String publishedSecondsAgo(Object count);

  /// No description provided for @publishedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String publishedMinutesAgo(Object count);

  /// No description provided for @publishedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String publishedHoursAgo(Object count);

  /// No description provided for @publishedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String publishedDaysAgo(Object count);

  /// No description provided for @publishedWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String publishedWeeksAgo(Object count);

  /// No description provided for @publishedMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String publishedMonthsAgo(Object count);

  /// No description provided for @publishedYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String publishedYearsAgo(Object count);

  /// No description provided for @viewCountTenThousand.
  ///
  /// In en, this message translates to:
  /// **'{count}0K'**
  String viewCountTenThousand(Object count);

  /// No description provided for @viewCountHundredMillion.
  ///
  /// In en, this message translates to:
  /// **'{count}00M'**
  String viewCountHundredMillion(Object count);

  /// No description provided for @viewCountFull.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String viewCountFull(Object count);

  /// No description provided for @animeCurrentSeasonLink.
  ///
  /// In en, this message translates to:
  /// **'Current season anime list (external link)'**
  String get animeCurrentSeasonLink;

  /// No description provided for @animeCurrentSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Current season anime'**
  String get animeCurrentSeasonTitle;

  /// No description provided for @animePastSeasonsLink.
  ///
  /// In en, this message translates to:
  /// **'Past season lists'**
  String get animePastSeasonsLink;

  /// No description provided for @animeLinkPending.
  ///
  /// In en, this message translates to:
  /// **'The link URL is not set yet'**
  String get animeLinkPending;

  /// No description provided for @continueWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continueWatchTitle;

  /// No description provided for @continueWatchHeaderLine1.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueWatchHeaderLine1;

  /// No description provided for @continueWatchHeaderLine2.
  ///
  /// In en, this message translates to:
  /// **'watching'**
  String get continueWatchHeaderLine2;

  /// No description provided for @continueWatchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continueWatchTooltip;

  /// No description provided for @continueWatchCurrentTab.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get continueWatchCurrentTab;

  /// No description provided for @continueWatchHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get continueWatchHistoryTab;

  /// No description provided for @continueWatchEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no videos available to continue watching'**
  String get continueWatchEmpty;

  /// No description provided for @continueWatchHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved playlists'**
  String get continueWatchHistoryEmpty;

  /// No description provided for @continueWatchLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved playlist limit'**
  String get continueWatchLimitTitle;

  /// No description provided for @continueWatchFreeLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can save up to {freeLimit} playlists.\nContinue Watching Pro increases the limit to {proLimit}.'**
  String continueWatchFreeLimitMessage(int freeLimit, int proLimit);

  /// No description provided for @continueWatchProLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can save up to {proLimit} playlists.\nDelete an unneeded playlist from History to save another.'**
  String continueWatchProLimitMessage(int proLimit);

  /// No description provided for @continueWatchOpenShop.
  ///
  /// In en, this message translates to:
  /// **'View shop'**
  String get continueWatchOpenShop;

  /// No description provided for @continueWatchOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get continueWatchOpenHistory;

  /// No description provided for @continueWatchExcluded.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get continueWatchExcluded;

  /// No description provided for @continueWatchStartCurrentList.
  ///
  /// In en, this message translates to:
  /// **'Start with this list'**
  String get continueWatchStartCurrentList;

  /// No description provided for @continueWatchPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get continueWatchPrevious;

  /// No description provided for @continueWatchNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get continueWatchNext;

  /// No description provided for @continueWatchHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get continueWatchHowTo;

  /// No description provided for @continueWatchHowToTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use Continue Watching'**
  String get continueWatchHowToTitle;

  /// No description provided for @continueWatchSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get continueWatchSelectAll;

  /// No description provided for @continueWatchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get continueWatchClearAll;

  /// No description provided for @continueWatchSelectionMenu.
  ///
  /// In en, this message translates to:
  /// **'Selection menu'**
  String get continueWatchSelectionMenu;

  /// No description provided for @continueWatchCompactView.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get continueWatchCompactView;

  /// No description provided for @continueWatchLargeView.
  ///
  /// In en, this message translates to:
  /// **'Large view'**
  String get continueWatchLargeView;

  /// No description provided for @continueWatchPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get continueWatchPlay;

  /// No description provided for @continueWatchPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get continueWatchPaused;

  /// No description provided for @continueWatchPin.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get continueWatchPin;

  /// No description provided for @continueWatchUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get continueWatchUnpin;

  /// No description provided for @continueWatchRestart.
  ///
  /// In en, this message translates to:
  /// **'Watch again'**
  String get continueWatchRestart;

  /// No description provided for @continueWatchRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get continueWatchRename;

  /// No description provided for @continueWatchQueueName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get continueWatchQueueName;

  /// No description provided for @continueWatchSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get continueWatchSave;

  /// No description provided for @continueWatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get continueWatchDelete;

  /// No description provided for @continueWatchDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this playlist?'**
  String get continueWatchDeleteTitle;

  /// No description provided for @continueWatchCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback complete'**
  String get continueWatchCompletedTitle;

  /// No description provided for @continueWatchCompleted.
  ///
  /// In en, this message translates to:
  /// **'You have finished the entire playlist. Thanks for watching.'**
  String get continueWatchCompleted;

  /// No description provided for @continueWatchNextCountdown.
  ///
  /// In en, this message translates to:
  /// **'Next video starts in {seconds} seconds'**
  String continueWatchNextCountdown(int seconds);

  /// No description provided for @continueWatchStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get continueWatchStop;

  /// No description provided for @continueWatchUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get continueWatchUpNext;

  /// No description provided for @continueWatchPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get continueWatchPlayNow;
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
    'that was used.',
  );
}
