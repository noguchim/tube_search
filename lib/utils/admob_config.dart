class AdMobConfig {
  // クローズドテスト中は true（デフォルト推奨）
  static const bool useTestAds =
      bool.fromEnvironment('TEST_ADS', defaultValue: true);

  // 公式テストID
  static const String testBannerId = "ca-app-pub-3940256099942544/6300978111";

  // ★あなたの本番バナーID
  static const String prodBannerId = "ca-app-pub-1955852466270592/7938489673";

  static String get bannerId => useTestAds ? testBannerId : prodBannerId;
}
