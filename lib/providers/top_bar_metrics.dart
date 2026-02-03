import 'package:flutter/cupertino.dart';

class TopBarMetrics extends ChangeNotifier {
  double _barContentHeight = 50;

  double get barContentHeight => _barContentHeight;

  void updateBarHeight(double height) {
    if (_barContentHeight == height) return;
    _barContentHeight = height;
    notifyListeners();
  }
}
