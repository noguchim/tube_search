// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navPopular => '人気急上昇';

  @override
  String get navGenre => 'ジャンル';

  @override
  String get navFavorites => 'お気に入り';

  @override
  String get navSettings => '設定';

  @override
  String get popularTitle => '人気急上昇';

  @override
  String infoTrendingUpdated(String region, String date) {
    return 'YouTube急上昇ランキング（$region・トレンド反映） $date 更新';
  }

  @override
  String get noVideosFound => '動画が見つかりません';

  @override
  String get genreScreenTitle => 'ジャンル別人気';

  @override
  String get genreSearchHeader => '検索して探す';

  @override
  String get genreNetworkError => 'ネットワークに接続できません';

  @override
  String get genreBrowseHeader => 'ジャンルから探す';

  @override
  String get favoritesTitle => 'お気に入り';

  @override
  String get favoritesEmptyTitle => 'お気に入りがありません';

  @override
  String get favoritesEmptyHint => '❤️アイコンタップでお気に入りに追加！';

  @override
  String get favoritesTapHere => 'ここをタップ！';

  @override
  String get favoritesRegisteredSuffix => '登録';

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
  String get settingsTitle => '設定';

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
  String get settingsFavoriteDeleteTitle => 'お気に入り削除時に確認';

  @override
  String get settingsFavoriteDeleteOn => 'する';

  @override
  String get settingsFavoriteDeleteOff => 'しない';

  @override
  String get settingsShop => 'ショップ';

  @override
  String get settingsShopSubtitle => '便利な機能でより快適に！';

  @override
  String get settingsPolicies => '各種ポリシー';

  @override
  String get settingsPoliciesSubtitle => 'プライバシー・利用規約';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

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
  String get settingsRegionSubtitle => 'アプリで表示する国を選択';

  @override
  String get regionJapan => '日本';

  @override
  String get regionUnitedStates => 'アメリカ';

  @override
  String get regionUnitedKingdom => 'イギリス';

  @override
  String get regionGermany => 'ドイツ';

  @override
  String get regionFrance => 'フランス';

  @override
  String get regionIndia => 'インド';

  @override
  String get repeatStatusOff => 'OFF';

  @override
  String get repeatStatusAscending => 'ON (昇順)';

  @override
  String get repeatStatusDescending => 'ON (降順)';

  @override
  String get repeatStatusRandom => 'ON (ランダム)';

  @override
  String get repeatDialogTitle => '連続再生の設定';

  @override
  String get repeatSettingsTitle => '連続再生の設定';

  @override
  String get repeatOptionOff => 'OFF（連続再生しない）';

  @override
  String get repeatOptionAscending => '昇順で再生';

  @override
  String get repeatOptionDescending => '降順で再生';

  @override
  String get repeatOptionRandom => 'ランダム再生';

  @override
  String get repeatDialogCancel => 'キャンセル';

  @override
  String get repeatDialogSave => '保存';

  @override
  String get repeatDialogMessage => '連続再生の動作を選択してください。';

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
  String get buttonOk => 'OK';
}
