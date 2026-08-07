// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get newPickupTitle => 'Picks';

  @override
  String get navPopular => 'Trending';

  @override
  String get navTopic => 'Topic';

  @override
  String get navGenre => 'Genres';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get noVideosFound => 'No videos were found';

  @override
  String get genreSearchHeader => 'Search videos';

  @override
  String get genreNetworkError => 'Cannot connect to the network';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyHint => 'Tap the heart icon to add favorites!';

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
      'You’ve reached the favorites limit.\nUpgrading lets you save more favorites.';

  @override
  String get favoriteLimitClose => 'Close';

  @override
  String get favoriteLimitUpgrade => 'Limit upgrade';

  @override
  String get update => 'updated';

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
  String get settingsShop => 'Shop';

  @override
  String get settingsShopSubtitle => 'More features';

  @override
  String get settingsPolicies => 'Policies';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get aboutRankingCalculation => 'How Rankings Are Calculated';

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
  String get shopTitleContinueWatchPro => 'Continue Watching Pro';

  @override
  String get shopDescContinueWatchPro => 'Expand saved playlists from 10 to 30';

  @override
  String get shopTitleAutoplay => 'Auto play';

  @override
  String get shopDescAutoplay => 'Automatically play videos one after another';

  @override
  String get shopPurchasedRemoveAds => 'Ads have been removed';

  @override
  String get shopPurchasedLimit => 'Limits have been upgraded';

  @override
  String get shopPurchasedContinueWatchPro =>
      'Continue Watching Pro is now active';

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
  String get regionJapan => 'Japan';

  @override
  String get regionUnitedStates => 'United States';

  @override
  String get regionUnitedKingdom => 'United Kingdom';

  @override
  String get favoriteLockedTitle => 'This video is locked';

  @override
  String get favoriteLockedMessage =>
      'This video is currently locked.\nUnlock it to remove from favorites.';

  @override
  String get favoriteUnlockTitle => 'Unlock this video?';

  @override
  String get favoriteUnlockMessage =>
      'Unlocking this video will allow it to be removed from favorites.';

  @override
  String get favoriteUnlockConfirm => 'Unlock';

  @override
  String get favoriteUnlockCancel => 'Cancel';

  @override
  String get favoriteLock => 'lock';

  @override
  String get favoriteDelete => 'delete';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String get updateAvailableMessage => 'The latest version is now available.';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update';

  @override
  String get buttonOk => 'OK';

  @override
  String get settingsAbout => 'About this App';

  @override
  String get browserOpenFailed => 'Failed to open the browser';

  @override
  String get updateNoticeTitle => 'Update Notice';

  @override
  String get appUpdatedMessage =>
      'The app has been updated to the latest version';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clear => 'Clear';

  @override
  String get trendWords => 'Trending Words';

  @override
  String get commonGame => 'Games';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get newBadge => 'New';

  @override
  String get liveBadge => 'Live';

  @override
  String get relatedVideos => 'Related videos';

  @override
  String get pickupRecommended => 'Recommended';

  @override
  String get pickupTrendMusic => 'Trending music';

  @override
  String get pushSettingsMenuTitle => 'Notifications';

  @override
  String get pushSettingsTitle => 'Notification settings';

  @override
  String get pushSettingsUpdateFailed =>
      'Could not update notification settings';

  @override
  String get pushPickupSectionTitle => 'Pick-up notifications';

  @override
  String get pushPickupDescription =>
      'Get notifications for new videos for each pick-up item.';

  @override
  String get pushPickupInitialWarningPrefix =>
      'Notifications are not sent while pick-ups are still at their default settings. To enable them, edit your items in ';

  @override
  String get pushPickupEditLink => 'Edit pick-ups';

  @override
  String get pushPickupInitialWarningSuffix => '.';

  @override
  String get pushTrendingSectionTitle => 'Fast-Rising Video Notifications';

  @override
  String get pushTrendingSectionSubtitle =>
      'Get notified about videos that are quickly gaining views after being posted.';

  @override
  String get pushTrendingTitle => 'Fast-Rising';

  @override
  String get pushItemNotSubscribable =>
      'Notifications are not available for this item';

  @override
  String get pickupEditTitle => 'Edit pick-ups';

  @override
  String get pickupEditDialogTitle => 'Change pick-ups';

  @override
  String get pickupEditDialogMessage => 'Set your pick-ups as shown below.';

  @override
  String get pickupEditCurrentSelection => 'Current selection';

  @override
  String get pickupEditGenreTab => 'Genres';

  @override
  String get pickupEditChannelTab => 'Channels';

  @override
  String get pickupEditFavoriteTab => 'Favorites';

  @override
  String get pickupEditFavoriteEmptyTitle => 'No favorites yet';

  @override
  String get pickupEditFavoriteEmptyMessage =>
      'When you add favorite videos, their channels will appear here.';

  @override
  String get pickupEditNewNotification => 'New video notifications';

  @override
  String get pickupEditSaveFailed => 'Failed to save settings';

  @override
  String pickupEditCategoryFallback(Object categoryId) {
    return 'Category $categoryId';
  }

  @override
  String get topicPickupEditTitle => 'Edit pick-ups';

  @override
  String get topicPickupEditMessage =>
      'Use the button at the bottom right to customize your pick-ups by genre or channel.';

  @override
  String get pickupEmptyNewVideos => 'No new videos yet';

  @override
  String get watchHistoryTitle => 'Watch history';

  @override
  String get watchHistoryEmpty => 'No watch history yet';

  @override
  String get videoPlayerOpenYoutubeTooltip => 'Open in YouTube';

  @override
  String get videoPlayerTitle => 'Playing on YouTube';

  @override
  String get videoPlayerDescription => 'Tap Open to view the video page.';

  @override
  String get videoPlayerOpening => 'Opening...';

  @override
  String get videoPlayerOpen => 'Open';

  @override
  String get settingsConfirmDeleteEnabled => 'Confirm';

  @override
  String get settingsConfirmDeleteDisabled => 'Do not confirm';

  @override
  String get topBarSortTooltip => 'Sort';

  @override
  String get sortByScore => 'Score';

  @override
  String get sortByViews => 'Views';

  @override
  String get sortByNewest => 'Newest';

  @override
  String publishedSecondsAgo(Object count) {
    return '${count}s ago';
  }

  @override
  String publishedMinutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String publishedHoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String publishedDaysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String publishedWeeksAgo(Object count) {
    return '${count}w ago';
  }

  @override
  String publishedMonthsAgo(Object count) {
    return '${count}mo ago';
  }

  @override
  String publishedYearsAgo(Object count) {
    return '${count}y ago';
  }

  @override
  String viewCountTenThousand(Object count) {
    return '${count}0K';
  }

  @override
  String viewCountHundredMillion(Object count) {
    return '${count}00M';
  }

  @override
  String viewCountFull(Object count) {
    return '$count views';
  }

  @override
  String get animeCurrentSeasonLink =>
      'Current season anime list (external link)';

  @override
  String get animeCurrentSeasonTitle => 'Current season anime';

  @override
  String get animePastSeasonsLink => 'Past season lists';

  @override
  String get animeLinkPending => 'The link URL is not set yet';

  @override
  String get continueWatchTitle => 'Continue watching';

  @override
  String get continueWatchHeaderLine1 => 'Continue';

  @override
  String get continueWatchHeaderLine2 => 'watching';

  @override
  String get continueWatchTooltip => 'Continue watching';

  @override
  String get continueWatchCurrentTab => 'Now playing';

  @override
  String get continueWatchHistoryTab => 'History';

  @override
  String get continueWatchEmpty =>
      'There are no videos available to continue watching';

  @override
  String get continueWatchHistoryEmpty => 'No saved playlists';

  @override
  String get continueWatchLimitTitle => 'Saved playlist limit';

  @override
  String continueWatchFreeLimitMessage(int freeLimit, int proLimit) {
    return 'You can save up to $freeLimit playlists.\nContinue Watching Pro increases the limit to $proLimit.';
  }

  @override
  String continueWatchProLimitMessage(int proLimit) {
    return 'You can save up to $proLimit playlists.\nDelete an unneeded playlist from History to save another.';
  }

  @override
  String get continueWatchOpenShop => 'View shop';

  @override
  String get continueWatchOpenHistory => 'View history';

  @override
  String get continueWatchExcluded => 'Unavailable';

  @override
  String get continueWatchStartCurrentList => 'Start with this list';

  @override
  String get continueWatchPrevious => 'Previous';

  @override
  String get continueWatchNext => 'Next';

  @override
  String get continueWatchHowTo => 'How to use';

  @override
  String get continueWatchHowToTitle => 'How to use Continue Watching';

  @override
  String get continueWatchSelectAll => 'Select all';

  @override
  String get continueWatchClearAll => 'Clear all';

  @override
  String get continueWatchSelectionMenu => 'Selection menu';

  @override
  String get continueWatchCompactView => 'Compact view';

  @override
  String get continueWatchLargeView => 'Large view';

  @override
  String get continueWatchPlay => 'Play';

  @override
  String get continueWatchPaused => 'Paused';

  @override
  String get continueWatchPin => 'Save';

  @override
  String get continueWatchUnpin => 'Unsave';

  @override
  String get continueWatchRestart => 'Watch again';

  @override
  String get continueWatchRename => 'Rename';

  @override
  String get continueWatchQueueName => 'Playlist name';

  @override
  String get continueWatchSave => 'Save';

  @override
  String get continueWatchDelete => 'Delete';

  @override
  String get continueWatchDeleteTitle => 'Delete this playlist?';

  @override
  String get continueWatchCompletedTitle => 'Playback complete';

  @override
  String get continueWatchCompleted =>
      'You have finished the entire playlist. Thanks for watching.';

  @override
  String continueWatchNextCountdown(int seconds) {
    return 'Next video starts in $seconds seconds';
  }

  @override
  String get continueWatchStop => 'Stop';

  @override
  String get continueWatchUpNext => 'Up next';

  @override
  String get continueWatchPlayNow => 'Play now';
}
