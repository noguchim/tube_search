import 'dart:io';

class AdMobConfig {
  static const bool useTestAds =
      bool.fromEnvironment('TEST_ADS', defaultValue: true);

  static const String testBannerId = "ca-app-pub-3940256099942544/6300978111";

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
}
