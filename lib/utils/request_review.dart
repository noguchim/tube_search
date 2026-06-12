import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

final _inAppReview = InAppReview.instance;
const _reviewRequestedMonthKey = 'review_requested_month'; // "2025-06"
const _usageCountKey = 'app_usage_count';

Future<void> requestReviewIfAvailable() async {
  try {
    if (await _inAppReview.isAvailable()) {
      logger.i('📣 requestReview called');
      await _inAppReview.requestReview();
    }
  } catch (_) {
    // 失敗しても何もしない（重要）
  }
}

Future<bool> shouldAskForReviewThisMonth({
  required int minUsageCount,
}) async {
  final now = DateTime.now();

  // 月ゲート（6月・12月）
  if (now.month != 6 && now.month != 12) return false;

  final prefs = await SharedPreferences.getInstance();

  // 利用回数ゲート
  final usageCount = prefs.getInt(_usageCountKey) ?? 0;
  if (usageCount < minUsageCount) return false;

  // 今月すでに出していないか
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final last = prefs.getString(_reviewRequestedMonthKey);

  return last != monthKey;
}

Future<void> markReviewRequestedThisMonth() async {
  final now = DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  await prefs.setString(_reviewRequestedMonthKey, monthKey);
}

Future<int> incrementUsageCount() async {
  final prefs = await SharedPreferences.getInstance();
  final count = (prefs.getInt(_usageCountKey) ?? 0) + 1;
  await prefs.setInt(_usageCountKey, count);
  return count;
}

Future<void> maybeAskForReview() async {
  await incrementUsageCount();

  final canShow = await shouldAskForReviewThisMonth(
    minUsageCount: 3, // ← ここで調整（3〜7がおすすめ）
  );

  if (!canShow) return;

  await requestReviewIfAvailable();
  await markReviewRequestedThisMonth();
}
