// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get newPickupTitle => 'ピックアップ';

  @override
  String get navPopular => '人気急上昇';

  @override
  String get navTopic => 'トピック';

  @override
  String get navGenre => 'ジャンル';

  @override
  String get navFavorites => 'お気に入り';

  @override
  String get noVideosFound => '該当する動画が見つかりませんでした';

  @override
  String get genreSearchHeader => '検索して探す';

  @override
  String get genreNetworkError => 'ネットワークに接続できません';

  @override
  String get favoritesTitle => 'お気に入り';

  @override
  String get favoritesEmptyHint => '❤️アイコンタップでお気に入りに追加！';

  @override
  String favoritesCountMessage(Object current, Object limit) {
    return 'お気に入り登録数：$current / $limit 件';
  }

  @override
  String get favoriteDeleteTitle => 'お気に入りから削除しますか？';

  @override
  String favoriteDeleteMessage(Object title) {
    return '「$title」をお気に入りから削除します。';
  }

  @override
  String get favoriteDeleteCancel => 'キャンセル';

  @override
  String get favoriteDeleteConfirm => '削除';

  @override
  String get favoriteLimitTitle => 'お気に入り上限';

  @override
  String get favoriteLimitPurchased => 'お気に入りは最大50件まで追加できます。';

  @override
  String get favoriteLimitNotPurchased =>
      'お気に入りの上限に達しました。\n上限拡張で、さらに多く登録できるようになります。';

  @override
  String get favoriteLimitClose => '閉じる';

  @override
  String get favoriteLimitUpgrade => '上限を拡張する';

  @override
  String get update => '更新';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => 'デバイスのモードを使用';

  @override
  String get settingsThemeLight => 'ライトモード';

  @override
  String get settingsThemeDark => 'ダークモード';

  @override
  String get settingsThemeLabelSystem => 'デバイス設定';

  @override
  String get settingsThemeLabelLight => 'ライト';

  @override
  String get settingsThemeLabelDark => 'ダーク';

  @override
  String get settingsFavoriteDeleteTitle => 'お気に入り削除';

  @override
  String get settingsShop => 'ショップ';

  @override
  String get settingsShopSubtitle => '機能追加';

  @override
  String get settingsPolicies => '各種ポリシー';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get aboutRankingCalculation => '集計方法について';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get networkErrorTitle => 'ネットワークに接続できません';

  @override
  String get networkErrorDescription => '接続状態を確認してから再度お試しください。';

  @override
  String get networkErrorRetry => '再読み込み';

  @override
  String get shopTitleRemoveAds => '広告削除';

  @override
  String get shopDescRemoveAds => '広告を非表示にします';

  @override
  String get shopTitleLimit => '上限拡張';

  @override
  String get shopDescLimit => '人気一覧表示とお気に入り登録の上限大幅アップ';

  @override
  String get shopTitleAutoplay => '連続再生';

  @override
  String get shopDescAutoplay => '動画を自動で連続再生';

  @override
  String get shopPurchasedRemoveAds => '広告を削除しました';

  @override
  String get shopPurchasedLimit => '上限を拡張しました';

  @override
  String get shopPurchased => '購入済み';

  @override
  String shopBuy(Object price) {
    return '$price\n(購入する)';
  }

  @override
  String get shopRestore => '購入を復元';

  @override
  String get shopLoadFailed => '商品情報を取得できませんでした';

  @override
  String get shopRestoreAlready => 'すでに購入が反映されています';

  @override
  String get shopRestoreNothing => '復元できる購入はありませんでした';

  @override
  String get shopRestoreDone => '購入を復元しました';

  @override
  String get settingsRegion => '地域';

  @override
  String get regionJapan => '日本';

  @override
  String get regionUnitedStates => 'アメリカ';

  @override
  String get regionUnitedKingdom => 'イギリス';

  @override
  String get favoriteLockedTitle => 'ロック中の動画です';

  @override
  String get favoriteLockedMessage => 'この動画はロックされています。\n削除するにはロックを解除してください。';

  @override
  String get favoriteUnlockTitle => 'ロックを解除しますか？';

  @override
  String get favoriteUnlockMessage => 'この動画のロックを解除すると、\nお気に入りから削除できるようになります。';

  @override
  String get favoriteUnlockConfirm => '解除する';

  @override
  String get favoriteUnlockCancel => 'キャンセル';

  @override
  String get favoriteLock => 'ロック';

  @override
  String get favoriteDelete => '削除';

  @override
  String get updateAvailableTitle => '新しいバージョンがあります';

  @override
  String get updateAvailableMessage => '最新版が公開されています。';

  @override
  String get updateLater => 'あとで';

  @override
  String get updateNow => '更新';

  @override
  String get buttonOk => 'OK';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get browserOpenFailed => 'ブラウザを開けませんでした';

  @override
  String get updateNoticeTitle => 'アップデートのお知らせ';

  @override
  String get appUpdatedMessage => 'アプリが最新版に更新されました';

  @override
  String get recentSearches => '最近の検索';

  @override
  String get clear => '消去';

  @override
  String get trendWords => 'トレンドワード';

  @override
  String get commonGame => 'ゲーム';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDone => '完了';

  @override
  String get newBadge => '新着';

  @override
  String get relatedVideos => '関連動画';

  @override
  String get pickupRecommended => 'おすすめ';

  @override
  String get pickupTrendMusic => 'トレンド音楽';

  @override
  String get pushSettingsMenuTitle => '通知';

  @override
  String get pushSettingsTitle => '通知の設定';

  @override
  String get pushSettingsUpdateFailed => '通知設定を更新できませんでした';

  @override
  String get pushPickupSectionTitle => 'ピックアップの通知';

  @override
  String get pushPickupDescription => 'ピックアップ項目ごとに新着動画を通知します。';

  @override
  String get pushPickupInitialWarningPrefix =>
      'ピックアップ項目が初期状態の場合は通知は行われません。通知を行う場合は';

  @override
  String get pushPickupEditLink => 'ピックアップ編集';

  @override
  String get pushPickupInitialWarningSuffix => 'でピックアップ項目の編集を行ってください。';

  @override
  String get pushTrendingSectionTitle => '人気動画の通知';

  @override
  String get pushTrendingSectionSubtitle => '急上昇動画を通知します。';

  @override
  String get pushTrendingTitle => '人気急上昇';

  @override
  String get pushItemNotSubscribable => 'この項目は通知対象外です';

  @override
  String get pickupEditTitle => 'ピックアップ編集';

  @override
  String get pickupEditDialogTitle => 'ピックアップ変更';

  @override
  String get pickupEditDialogMessage => '下記の内容でピックアップを設定します。';

  @override
  String get pickupEditCurrentSelection => '現在設定中';

  @override
  String get pickupEditGenreTab => 'ジャンル';

  @override
  String get pickupEditChannelTab => 'チャンネル';

  @override
  String get pickupEditFavoriteTab => 'お気に入り';

  @override
  String get pickupEditFavoriteEmptyTitle => 'まだお気に入りがありません';

  @override
  String get pickupEditFavoriteEmptyMessage =>
      'お気に入り登録すると、登録された動画のチャンネルがここに表示されます';

  @override
  String get pickupEditNewNotification => '新着通知';

  @override
  String get pickupEditSaveFailed => '設定の保存に失敗しました';

  @override
  String pickupEditCategoryFallback(Object categoryId) {
    return 'カテゴリ $categoryId';
  }

  @override
  String get topicPickupEditTitle => 'ピックアップの編集';

  @override
  String get topicPickupEditMessage =>
      'ピックアップをお好みのジャンルやチャンネルに変更したい場合は、右下のボタンをタップ！';

  @override
  String get pickupEmptyNewVideos => 'まだ新着動画がありません';

  @override
  String get watchHistoryTitle => '視聴履歴';

  @override
  String get watchHistoryEmpty => '視聴履歴がありません';

  @override
  String get videoPlayerOpenYoutubeTooltip => 'YouTubeで開く';

  @override
  String get videoPlayerTitle => 'YouTubeで再生します';

  @override
  String get videoPlayerDescription => '「開く」を押すと動画ページを表示します。';

  @override
  String get videoPlayerOpening => '開いています...';

  @override
  String get videoPlayerOpen => '開く';

  @override
  String get settingsConfirmDeleteEnabled => '確認する';

  @override
  String get settingsConfirmDeleteDisabled => '確認しない';

  @override
  String get topBarSortTooltip => '並び替え';

  @override
  String get sortByScore => 'スコア順';

  @override
  String get sortByViews => '再生順';

  @override
  String get sortByNewest => '新着順';

  @override
  String publishedSecondsAgo(Object count) {
    return '$count秒前';
  }

  @override
  String publishedMinutesAgo(Object count) {
    return '$count分前';
  }

  @override
  String publishedHoursAgo(Object count) {
    return '$count時間前';
  }

  @override
  String publishedDaysAgo(Object count) {
    return '$count日前';
  }

  @override
  String publishedWeeksAgo(Object count) {
    return '$count週間前';
  }

  @override
  String publishedMonthsAgo(Object count) {
    return '$countヶ月前';
  }

  @override
  String publishedYearsAgo(Object count) {
    return '$count年前';
  }

  @override
  String viewCountTenThousand(Object count) {
    return '$count万';
  }

  @override
  String viewCountHundredMillion(Object count) {
    return '$count億';
  }

  @override
  String viewCountFull(Object count) {
    return '$count回視聴';
  }

  @override
  String get animeCurrentSeasonLink => '今期アニメ一覧はこちら（外部リンク）';

  @override
  String get animeCurrentSeasonTitle => '今期アニメ一覧';

  @override
  String get animePastSeasonsLink => '過去のシーズン一覧';

  @override
  String get animeLinkPending => 'リンク先は未設定です';
}
