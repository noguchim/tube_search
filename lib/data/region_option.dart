import '../l10n/app_localizations.dart';

class RegionOption {
  final String code;
  final String Function(AppLocalizations l) label; // ← 翻訳関数
  final String flag;

  const RegionOption({
    required this.code,
    required this.label,
    required this.flag,
  });
}

final regionOptions = [
  RegionOption(
    code: "JP",
    flag: "🇯🇵",
    label: (l) => l.regionJapan,
  ),
  RegionOption(
    code: "US",
    flag: "🇺🇸",
    label: (l) => l.regionUnitedStates,
  ),
];
