import 'package:flutter/widgets.dart';

String formatViewCount(BuildContext context, String value) {
  final num? number = num.tryParse(value);
  if (number == null) return '0';

  final locale = Localizations.localeOf(context).languageCode;

  // 🇯🇵 日本形式（万 / 億）
  if (locale == 'ja') {
    if (number < 10000) {
      return '${number.toInt()}回視聴';
    } else if (number < 100000000) {
      final man = number / 10000;
      final formatted = man.toStringAsFixed(man < 10 ? 1 : 0);
      return '$formatted万回視聴';
    } else {
      final oku = number / 100000000;
      return '${oku.toStringAsFixed(1)}億回視聴';
    }
  }

  // 🌎 英語形式（K / M / B）
  if (number < 1000) {
    return '${number.toInt()} views';
  } else if (number < 1000000) {
    return '${(number / 1000).toStringAsFixed(1)}K views';
  } else if (number < 1000000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M views';
  } else {
    return '${(number / 1000000000).toStringAsFixed(1)}B views';
  }
}
