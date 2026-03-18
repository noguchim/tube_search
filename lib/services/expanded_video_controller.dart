import 'package:flutter/foundation.dart';

import '../data/youtube_video.dart';

class ExpandedVideoController extends ChangeNotifier {
  YouTubeVideo? _video;
  int? _rank;

  YouTubeVideo? get video => _video;

  int? get rank => _rank;

  bool get isOpen => _video != null;

  void open(YouTubeVideo video, int rank) {
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
