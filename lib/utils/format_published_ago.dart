import 'app_logger.dart';

String formatPublishedAgo(DateTime? published) {
  if (published == null) return "";

  final now = DateTime.now();
  final diff = now.difference(published);

  logger.i("[formatPublishedAgo]published=$published now=$now diff=$diff");

  if (diff.inSeconds < 60) {
    return "${diff.inSeconds}秒前";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes}分前";
  } else if (diff.inHours < 24) {
    return "${diff.inHours}時間前";
  } else if (diff.inDays < 7) {
    return "${diff.inDays}日前";
  } else if (diff.inDays < 30) {
    return "${(diff.inDays / 7).floor()}週間前";
  } else if (diff.inDays < 365) {
    return "${(diff.inDays / 30).floor()}ヶ月前";
  } else {
    return "${(diff.inDays / 365).floor()}年前";
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
