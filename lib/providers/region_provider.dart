import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionProvider extends ChangeNotifier {
  static const _prefRegion = "region_code";

  String _regionCode = "JP";

  String get regionCode => _regionCode;

  // 対応リージョン
  static const _supported = [
    "JP",
    "US",
    "GB",
    "KR",
    "DE",
    "FR",
    "IN",
  ];

  // --------------------------------------------------
  // ⭐ 初期化（保存 → 端末推定 → US フォールバック）
  // --------------------------------------------------
  Future<void> initFromLocale(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefRegion);

    if (saved != null) {
      _regionCode = saved;
      debugPrint("🌏 [Region] loaded from storage → $_regionCode");
      return;
    }

    final deviceLocale = Platform.localeName;
    debugPrint("🌏 [Region] device locale = $deviceLocale");

    final parts = deviceLocale.split("_");
    final country = parts.length > 1 ? parts.last : "US";

    if (_supported.contains(country)) {
      _regionCode = country;
      debugPrint("🌏 [Region] detected & supported → $_regionCode");
    } else {
      _regionCode = "US";
      debugPrint(
        "🌏 [Region] unsupported ($country) → fallback to US",
      );
    }

    await prefs.setString(_prefRegion, _regionCode);
    debugPrint("🌏 [Region] saved initial region → $_regionCode");
  }

  // --------------------------------------------------
  // ⭐ 変更（保存 + 通知）
  // --------------------------------------------------
  Future<void> setRegion(String code) async {
    _regionCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRegion, code);

    debugPrint("🌏 [Region] changed manually → $_regionCode");

    notifyListeners();
  }
}
