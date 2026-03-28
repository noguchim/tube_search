import 'dart:io';

class AdMobConfig {
  static const bool useTestAds =
      bool.fromEnvironment('TEST_ADS', defaultValue: false);

  static const String testBannerId = "ca-app-pub-3940256099942544/6300978111";

  // iOS
  static const String prodBannerIdIOS =
      "ca-app-pub-1955852466270592/7938489673";

  // Android
  static const String prodBannerIdAndroid =
      "ca-app-pub-1955852466270592/1862587758";

  static String get bannerId {
    if (useTestAds) return testBannerId;

    if (Platform.isIOS) {
      return prodBannerIdIOS;
    } else if (Platform.isAndroid) {
      return prodBannerIdAndroid;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
