import 'package:flutter/material.dart';

enum RepeatMode {
  off,
  ascending,
  descending,
  random,
}

class RepeatProvider extends ChangeNotifier {
  RepeatMode _mode = RepeatMode.off;

  // 範囲指定（null は「未指定／全動画」扱い）
  int? _startIndex;
  int? _endIndex;

  bool _usePreset = true;

  RepeatMode get mode => _mode;

  int? get startIndex => _startIndex;

  int? get endIndex => _endIndex;

  bool get usePreset => _usePreset;

  // --------------------------------------------------
  // ⭐ 初期化（メモリなので何もしない）
  // --------------------------------------------------
  Future<void> init() async {
    debugPrint("🌀 Repeat init(): (memory only, nothing restored)");
  }

  // --------------------------------------------------
  // 🔁 モード変更
  // --------------------------------------------------
  void setMode(RepeatMode m) {
    _mode = m;
    debugPrint("💾 Repeat memory mode = $m");
    notifyListeners();
  }

  // --------------------------------------------------
  // 🎯 範囲（共通インターフェイス）
  // --------------------------------------------------
  void setRange({
    required int? start,
    required int? end,
    required bool usePreset,
  }) {
    _startIndex = start;
    _endIndex = end;
    _usePreset = usePreset;

    debugPrint("💾 Repeat memory range: $start-$end preset=$usePreset");

    notifyListeners();
  }
}
