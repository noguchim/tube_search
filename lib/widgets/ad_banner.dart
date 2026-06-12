import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/admob_config.dart';
import '../utils/app_logger.dart';
import 'consent_manager.dart';

class AdBanner extends StatefulWidget {
  final bool isMain;

  const AdBanner({
    super.key,
    required this.isMain,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  BannerAd? _banner;
  AdSize? _adSize; // ★ AdSize? にする（Adaptiveもbannerも入る）
  bool _isLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> _connSub;
  Timer? _refreshTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ★ レイアウト確定後に広告ロード（Tabletクラッシュ対策）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBanner();
        _startAutoRefresh();
      }
    });

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) return;

      if (mounted) _reloadBanner();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.i('🔄 App resumed → reload banner');
      _reloadBanner();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (!mounted) return;
      logger.i('🔄 Auto refresh banner');
      _reloadBanner();
    });
  }

  Future<void> _loadBanner() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final width = MediaQuery.of(context).size.width.toInt();
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      final adSize = adaptive ?? AdSize.banner;

      final adUnitId = AdMobConfig.bannerId(isMain: widget.isMain);

      logger.i('🧪 AdUnitId: $adUnitId');

      _banner?.dispose();

      late BannerAd banner;

      banner = BannerAd(
        size: adSize,
        adUnitId: adUnitId,
        request: AdRequest(
          nonPersonalizedAds: ConsentManager.nonPersonalizedAds,
        ),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            logger.i('🎯 Banner loaded');
            _isLoading = false;

            if (!mounted) return;

            setState(() {
              _banner = banner;
              _adSize = adSize;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            logger.i('❌ Banner failed: ${err.code}');
            _isLoading = false;
            ad.dispose();
          },
        ),
      );

      banner.load();
    } catch (e) {
      _isLoading = false;
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
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _connSub.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;

    return SizedBox(
      width: double.infinity,
      height: _isLoaded && _adSize != null ? _adSize!.height.toDouble() : 50,
      child: (_isLoaded && banner != null) && !AdMobConfig.useTestAds
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
