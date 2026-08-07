import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/admob_config.dart';
import '../utils/app_logger.dart';
import '../widgets/consent_manager.dart';

class ContinueWatchInterstitialService {
  static const _maxCacheAge = Duration(minutes: 50);

  static bool _isUnsupportedOrientation(bool isLandscape) {
    return defaultTargetPlatform == TargetPlatform.iOS && isLandscape;
  }

  InterstitialAd? _ad;
  DateTime? _loadedAt;
  bool? _loadedLandscape;
  bool _isLoading = false;
  bool? _loadingLandscape;
  bool? _pendingLandscape;
  bool _isDisposed = false;

  void load({
    required bool enabled,
    required bool isLandscape,
    required bool enforceOrientation,
  }) {
    if (!enabled || _isDisposed || _isUnsupportedOrientation(isLandscape)) {
      return;
    }
    if (_isLoading) {
      if (enforceOrientation && _loadingLandscape != isLandscape) {
        _pendingLandscape = isLandscape;
      }
      return;
    }

    final loadedAt = _loadedAt;
    final hasFreshAd =
        _ad != null &&
        loadedAt != null &&
        (!enforceOrientation || _loadedLandscape == isLandscape) &&
        DateTime.now().difference(loadedAt) < _maxCacheAge;
    if (hasFreshAd) return;

    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
    _loadedLandscape = null;

    final adUnitId = AdMobConfig.continueWatchInterstitialId();
    if (adUnitId == null) {
      logger.i('[CONTINUE_WATCH_AD] Ad unit ID is not configured');
      return;
    }

    _isLoading = true;
    _loadingLandscape = isLandscape;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(nonPersonalizedAds: ConsentManager.nonPersonalizedAds),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _loadingLandscape = null;
          if (_isDisposed) {
            ad.dispose();
            return;
          }
          final pendingLandscape = _pendingLandscape;
          _pendingLandscape = null;
          if (pendingLandscape != null && pendingLandscape != isLandscape) {
            ad.dispose();
            load(
              enabled: true,
              isLandscape: pendingLandscape,
              enforceOrientation: true,
            );
            return;
          }
          _ad = ad;
          _loadedAt = DateTime.now();
          _loadedLandscape = isLandscape;
          logger.i('[CONTINUE_WATCH_AD] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _loadingLandscape = null;
          logger.i(
            '[CONTINUE_WATCH_AD] Interstitial load failed: ${error.code}',
          );
          final pendingLandscape = _pendingLandscape;
          _pendingLandscape = null;
          if (pendingLandscape != null) {
            load(
              enabled: true,
              isLandscape: pendingLandscape,
              enforceOrientation: true,
            );
          }
        },
      ),
    );
  }

  bool showIfAvailable({
    required bool isLandscape,
    required bool enforceOrientation,
    required void Function() onFinished,
  }) {
    if (_isDisposed || _isUnsupportedOrientation(isLandscape)) return false;
    final ad = _ad;
    final loadedAt = _loadedAt;
    if (ad == null ||
        loadedAt == null ||
        (enforceOrientation && _loadedLandscape != isLandscape) ||
        DateTime.now().difference(loadedAt) >= _maxCacheAge) {
      ad?.dispose();
      _ad = null;
      _loadedAt = null;
      _loadedLandscape = null;
      return false;
    }

    _ad = null;
    _loadedAt = null;
    _loadedLandscape = null;
    var callbackSent = false;
    void finish() {
      if (callbackSent) return;
      callbackSent = true;
      onFinished();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        logger.i('[CONTINUE_WATCH_AD] Interstitial show failed: ${error.code}');
        shownAd.dispose();
        finish();
      },
    );

    try {
      ad.show();
      return true;
    } catch (error) {
      logger.i('[CONTINUE_WATCH_AD] Interstitial show error: $error');
      ad.dispose();
      finish();
      return true;
    }
  }

  Future<bool> waitUntilAvailable({
    required bool isLandscape,
    required bool enforceOrientation,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_isDisposed || _isUnsupportedOrientation(isLandscape)) return false;

    final deadline = DateTime.now().add(timeout);
    while (!_isDisposed && DateTime.now().isBefore(deadline)) {
      final loadedAt = _loadedAt;
      final isAvailable =
          _ad != null &&
          loadedAt != null &&
          (!enforceOrientation || _loadedLandscape == isLandscape) &&
          DateTime.now().difference(loadedAt) < _maxCacheAge;
      if (isAvailable) return true;
      if (!_isLoading) return false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return false;
  }

  void dispose() {
    _isDisposed = true;
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
    _loadedLandscape = null;
    _loadingLandscape = null;
    _pendingLandscape = null;
  }
}
