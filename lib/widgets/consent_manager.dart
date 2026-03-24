import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/app_logger.dart';

class ConsentManager {
  static bool _nonPersonalizedAds = true;

  static bool get nonPersonalizedAds => _nonPersonalizedAds;

  static Future<void> requestConsent() async {
    final consentInfo = ConsentInformation.instance;

    // 🔥 Debug時のみリセット
    assert(() {
      consentInfo.reset();
      return true;
    }());

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
    );

    // -----------------------------
    // ① Consent情報更新
    // -----------------------------
    final completer = Completer<void>();

    consentInfo.requestConsentInfoUpdate(
      params,
      () => completer.complete(),
      (error) {
        logger.e('⚠️ UMP request error: ${error.message}');
        completer.complete();
      },
    );

    await completer.future;

    final status = await consentInfo.getConsentStatus();
    final isAvailable =
        await ConsentInformation.instance.isConsentFormAvailable();

    logger.i('🔎 consent status = $status');
    logger.i('🔥 form available = $isAvailable');

    // -----------------------------
    // ② フォーム表示（正規API）
    // -----------------------------
    final formCompleter = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired(
      (error) async {
        if (error != null) {
          logger.e('⚠️ UMP error: ${error.message}');
        }

        await _updateConsentStatus();
        formCompleter.complete();
      },
    );

    await formCompleter.future;
  }

  // -----------------------------
  // ③ ステータス反映
  // -----------------------------
  static Future<void> _updateConsentStatus() async {
    final status = await ConsentInformation.instance.getConsentStatus();

    logger.i('🔎 consent status = $status');

    switch (status) {
      case ConsentStatus.obtained:
        _nonPersonalizedAds = false;
        break;

      default:
        _nonPersonalizedAds = true;
        break;
    }

    logger.i('🎯 nonPersonalizedAds = $_nonPersonalizedAds');
  }
}
