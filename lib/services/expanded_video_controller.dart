import 'package:flutter/foundation.dart';

import '../data/youtube_video.dart';

enum VideoPresentationMode {
  ranked, // ランキング文脈: rank / score / popularity を表示
  plain, // 通常文脈: rank / score / popularity を非表示
}

class ExpandedVideoController extends ChangeNotifier {
  YouTubeVideo? _video;
  int? _rank;
  VideoPresentationMode _presentationMode = VideoPresentationMode.ranked;

  YouTubeVideo? get video => _video;

  int? get rank => _rank;

  bool get isOpen => _video != null;

  VideoPresentationMode get presentationMode => _presentationMode;

  bool get showRankingInfo => _presentationMode == VideoPresentationMode.ranked;

  void open(
    YouTubeVideo video,
    int rank, {
    VideoPresentationMode presentationMode = VideoPresentationMode.ranked,
  }) {
    _video = video;
    _rank = rank;
    _presentationMode = presentationMode;
    notifyListeners();
  }

  void close() {
    if (_video == null && _rank == null) return;
    _video = null;
    _rank = null;
    _presentationMode = VideoPresentationMode.ranked;
    notifyListeners();
  }
}
