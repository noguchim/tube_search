import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionProvider extends ChangeNotifier {
  static const _prefRegion = "region_code";

  String _regionCode = "JP";

  String get regionCode => _regionCode;

  // --------------------------------------------------
  // ⭐ 初期化：保存があればそれを使う → なければ Locale から推定
  // --------------------------------------------------
  Future<void> initFromLocale(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefRegion);

    if (saved != null) {
      _regionCode = saved;
      return; // ← notifyListeners() しない（UIはまだ構築前）
    }

    final locale = Localizations.localeOf(context);

    if (locale.countryCode == "US") {
      _regionCode = "US";
    } else {
      _regionCode = "JP";
    }
  }

  // --------------------------------------------------
  // ⭐ 変更時：保存 + 反映
  // --------------------------------------------------
  Future<void> setRegion(String code) async {
    _regionCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRegion, code);

    notifyListeners();
  }
}
