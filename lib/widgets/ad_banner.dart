import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/app_logger.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _isLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> _connSub;

  @override
  void initState() {
    super.initState();
    _loadBanner();

    // ★ ネットワーク変化を購読
    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        _reloadBanner();
      }
    });
  }

  // バナー初回ロード
  void _loadBanner() {
    _banner = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-1955852466270592/7938489673",
      // AdMob 公式テスト ID
      // adUnitId: "ca-app-pub-3940256099942544/6300978111",
      listener: BannerAdListener(
        onAdLoaded: (_) {
          logger.i('🎯 Banner loaded OK');
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          logger.i('❌ Banner failed: ${err.code} / ${err.message}');

          ad.dispose();
          setState(() {
            _isLoaded = false;
            _banner = null;
          });
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  // ネット変化で強制 reload
  void _reloadBanner() {
    setState(() {
      _isLoaded = false;
      _banner?.dispose();
      _banner = null;
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
    const bool debugMode = false;

    // ★ どちらにせよ高さは 50px で統一
    return SizedBox(
      height: 50,
      // For capture
      child: _buildDummyBannerGlass(context),

      // child: (_isLoaded && banner != null) && !debugMode
      //     ? AdWidget(ad: banner)
      //     : _buildDummyBannerGlass(context), // ← バナーなし時はこれ
    );
  }

  // ------------------------------
  // ⭐ ダミーバナー（背景 + アプリ名）
  // ------------------------------
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
