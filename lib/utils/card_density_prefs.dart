import 'package:shared_preferences/shared_preferences.dart';

enum CardDensity { big, side, middle, small }

class CardDensityPrefs {
  /// 画面ごとにキーを変えたい場合は引数で渡す
  static const String defaultKey = 'card_density_global';

  static Future<CardDensity> load({String key = defaultKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    return switch (raw) {
      'big' => CardDensity.big,
      'side' => CardDensity.side,
      'middle' => CardDensity.middle,
      'small' => CardDensity.small,
      _ => CardDensity.big,
    };
  }

  static Future<void> save(CardDensity density,
      {String key = defaultKey}) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = switch (density) {
      CardDensity.big => 'big',
      CardDensity.side => 'side',
      CardDensity.middle => 'middle',
      CardDensity.small => 'small',
    };

    await prefs.setString(key, raw);
  }

  static CardDensity next(CardDensity current) {
    return switch (current) {
      CardDensity.big => CardDensity.side,
      CardDensity.side => CardDensity.middle,
      CardDensity.middle => CardDensity.small,
      CardDensity.small => CardDensity.big,
    };
  }
}
