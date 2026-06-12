import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';

String formatPublishedAgo(BuildContext context, DateTime? published) {
  if (published == null) return "";
  final l = AppLocalizations.of(context)!;

  final now = DateTime.now();
  final diff = now.difference(published);

  if (diff.inSeconds < 60) {
    return l.publishedSecondsAgo(diff.inSeconds);
  } else if (diff.inMinutes < 60) {
    return l.publishedMinutesAgo(diff.inMinutes);
  } else if (diff.inHours < 24) {
    return l.publishedHoursAgo(diff.inHours);
  } else if (diff.inDays < 14) {
    return l.publishedDaysAgo(diff.inDays);
  } else if (diff.inDays < 30) {
    return l.publishedWeeksAgo((diff.inDays / 7).floor());
  } else if (diff.inDays < 365) {
    return l.publishedMonthsAgo((diff.inDays / 30).floor());
  } else {
    return l.publishedYearsAgo((diff.inDays / 365).floor());
  }
}

String separator(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'ja') {
    return '・';
  } else {
    return ' • ';
  }
}

String formatDuration(int seconds) {
  if (seconds <= 0) return "0:00";

  final duration = Duration(seconds: seconds);

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);

  String two(int n) => n.toString().padLeft(2, '0');

  if (hours > 0) {
    return "$hours:${two(minutes)}:${two(secs)}";
  } else {
    return "$minutes:${two(secs)}";
  }
}
