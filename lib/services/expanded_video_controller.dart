import 'package:flutter/foundation.dart';

class ExpandedVideoController extends ChangeNotifier {
  Map<String, dynamic>? _video;
  int? _rank;

  Map<String, dynamic>? get video => _video;

  int? get rank => _rank;

  bool get isOpen => _video != null;

  void open(Map<String, dynamic> video, int rank) {
    _video = video;
    _rank = rank;
    notifyListeners();
  }

  void close() {
    _video = null;
    _rank = null;
    notifyListeners();
  }
}
