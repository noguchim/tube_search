import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/admob_config.dart';
import '../utils/app_logger.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  AdSize? _adSize; // ★ AdSize? にする（Adaptiveもbannerも入る）
  bool _isLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> _connSub;

  @override
  void initState() {
    super.initState();

    // ★ レイアウト確定後に広告ロード（Tabletクラッシュ対策）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBanner();
      }
    });

    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      if (mounted) _reloadBanner();
    });
  }

  Future<void> _loadBanner() async {
    try {
      final width = MediaQuery.of(context).size.width.toInt();

      // ★ Adaptiveを取得（取得できなければ通常bannerにフォールバック）
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      _adSize = adaptive ?? AdSize.banner;

      // 既存バナーがあれば破棄
      _banner?.dispose();
      _banner = null;

      _banner = BannerAd(
        size: _adSize!,
        adUnitId: AdMobConfig.bannerId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            logger.i('🎯 Banner loaded: ${_adSize?.width}x${_adSize?.height}');
            if (!mounted) return;
            setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, err) {
            logger.i('❌ Banner failed: ${err.code} / ${err.message}');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _banner = null;
              _isLoaded = false;
            });
          },
        ),
      );

      await _banner!.load();
    } catch (e, st) {
      logger.e('💥 Banner load error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _banner?.dispose();
        _banner = null;
        _isLoaded = false;
        _adSize = null;
      });
    }
  }

  void _reloadBanner() {
    setState(() {
      _isLoaded = false;
      _banner?.dispose();
      _banner = null;
      _adSize = null;
    });
    _loadBanner();
  }

  @override
  void dispose() {
    _connSub.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    const bool debugMode = true;

    return SizedBox(
      width: double.infinity,
      height: _isLoaded && _adSize != null ? _adSize!.height.toDouble() : 50,
      child: (_isLoaded && banner != null) && !debugMode
          ? AdWidget(ad: banner)
          : _buildDummyBannerGlass(context),
    );
  }

  Widget _buildDummyBannerGlass(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.35),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.12),
                width: 0.7,
              ),
            ),
          ),
          child: Text(
            "TUBE+ AD",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.70)
                  : Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}
