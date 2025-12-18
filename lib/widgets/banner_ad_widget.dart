// lib/widgets/banner_ad_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/banner_ad_provider.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BannerAdProvider>();

    if (!provider.isLoaded || provider.banner == null) {
      return const SizedBox(height: 50); // ロード中の空白
    }

    return SizedBox(
      height: 50,
      child: AdWidget(ad: provider.banner!),
    );
  }
}
