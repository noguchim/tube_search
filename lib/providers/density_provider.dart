import 'package:flutter/cupertino.dart';

import '../utils/card_density_prefs.dart';

class DensityProvider extends ChangeNotifier {
  static const _key = 'popular_card_density';

  CardDensity _density = CardDensity.big;

  CardDensity get density => _density;

  Future<void> load() async {
    _density = await CardDensityPrefs.load(key: _key);
    notifyListeners();
  }

  void toggle() {
    _density = CardDensityPrefs.next(_density);
    CardDensityPrefs.save(_density, key: _key);
    notifyListeners();
  }
}
