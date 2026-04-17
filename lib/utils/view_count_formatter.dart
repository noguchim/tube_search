import 'package:flutter/cupertino.dart';

enum ViewCountFormat {
  compact, // 1.2万 / 1.2M
  full, // 1.2万回視聴 / 1.2M views
}

String formatViewCount(
  BuildContext context,
  String value, {
  ViewCountFormat format = ViewCountFormat.full,
}) {
  final num? number = num.tryParse(value);
  if (number == null) return '0';

  final locale = Localizations.localeOf(context).languageCode;
  final isJP = locale == 'ja';

  // =========================
  // 🇯🇵 日本
  // =========================
  if (isJP) {
    String text;

    if (number < 10000) {
      text = number.toInt().toString();
    } else if (number < 100000000) {
      final man = number / 10000;
      final formatted =
          man < 10 ? man.toStringAsFixed(1) : man.toStringAsFixed(0);
      text = '$formatted万';
    } else {
      final oku = number / 100000000;
      text = '${oku.toStringAsFixed(1)}億';
    }

    return format == ViewCountFormat.full ? '${text}回視聴' : text;
  }

  // =========================
  // 🌎 英語
  // =========================
  String text;

  if (number < 1000) {
    text = number.toInt().toString();
  } else if (number < 1000000) {
    final v = number / 1000;
    text = v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
    text = '${text}K';
  } else if (number < 1000000000) {
    final v = number / 1000000;
    text = v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
    text = '${text}M';
  } else {
    final v = number / 1000000000;
    text = '${v.toStringAsFixed(1)}B';
  }

  return format == ViewCountFormat.full ? '$text views' : text;
}
