// widgets/repeat/repeat_types.dart

enum RepeatTab {
  newSetting,
  history,
}

enum SortMode {
  asc,
  desc,
  random,
}

enum PreviewAction {
  cancel,
  saveOnly,
  saveAndPlay,
}

class RangeSettingResult {
  final SortMode sortMode;
  final int startIndex;
  final int endIndex;

  RangeSettingResult({
    required this.sortMode,
    required this.startIndex,
    required this.endIndex,
  });
}
