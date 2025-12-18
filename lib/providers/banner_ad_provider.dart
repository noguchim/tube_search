// lib/providers/banner_ad_provider.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdProvider extends ChangeNotifier {
  BannerAd? banner;
  bool isLoaded = false;

  static const String testBannerId = "ca-app-pub-3940256099942544/6300978111";

  BannerAdProvider() {
    _loadAd();
  }

  void _loadAd() {
    banner = BannerAd(
      adUnitId: testBannerId,
      size: AdSize.banner, // 高さ50px
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isLoaded = false;
          notifyListeners();
        },
      ),
    );

    banner!.load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }
}
