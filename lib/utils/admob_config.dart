import 'dart:io';

import 'package:flutter/foundation.dart';

class AdMobConfig {
  // flutter run / Xcode Runではスクリーンショット用バナーを表示する。
  // Store向けのReleaseビルドでは通常の広告表示に切り替わる。
  static const bool useDummyBanner = !kReleaseMode;

  static const bool useTestAds = bool.fromEnvironment(
    'TEST_ADS',
    defaultValue: false,
  );

  static const bool forceAds = bool.fromEnvironment(
    'FORCE_ADS',
    defaultValue: false,
  );

  static const String testBannerId = "ca-app-pub-3940256099942544/6300978111";

  static const String testInterstitialIOS =
      "ca-app-pub-3940256099942544/4411468910";
  static const String testInterstitialAndroid =
      "ca-app-pub-3940256099942544/1033173712";

  // ===== メイン =====
  static const String prodBannerMainIOS =
      "ca-app-pub-1955852466270592/7938489673";

  static const String prodBannerMainAndroid =
      "ca-app-pub-1955852466270592/1862587758";

  // ===== サブ =====
  static const String prodBannerSubIOS =
      "ca-app-pub-1955852466270592/1015273811";

  static const String prodBannerSubAndroid =
      "ca-app-pub-1955852466270592/6482493967";

  static const String prodContinueWatchInterstitialIOS =
      "ca-app-pub-1955852466270592/8575797468";
  static const String prodContinueWatchInterstitialAndroid =
      "ca-app-pub-1955852466270592/3329395556";

  static String bannerId({required bool isMain}) {
    if (useTestAds) return testBannerId;

    if (Platform.isIOS) {
      return isMain ? prodBannerMainIOS : prodBannerSubIOS;
    } else if (Platform.isAndroid) {
      return isMain ? prodBannerMainAndroid : prodBannerSubAndroid;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String? continueWatchInterstitialId() {
    if (!kReleaseMode || useTestAds) {
      if (Platform.isIOS) return testInterstitialIOS;
      if (Platform.isAndroid) return testInterstitialAndroid;
      return null;
    }

    final id = Platform.isIOS
        ? prodContinueWatchInterstitialIOS
        : Platform.isAndroid
        ? prodContinueWatchInterstitialAndroid
        : '';
    return id.isEmpty ? null : id;
  }

  static bool shouldShowAds({required bool adsRemoved}) {
    return forceAds || !adsRemoved;
  }
}
