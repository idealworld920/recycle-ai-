import 'package:flutter/foundation.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../schedule/notification_service.dart';
import 'purchases_service.dart';

/// 체험 종료 알림 (약속 지키기): 체험 시작 +5일 20:00, +6일 20:00 로컬 알림 2개.
/// 구독 취소·만료가 감지되면 취소한다. users/{uid}.trialEndsAt 은 나중에 서버 푸시로 바꿀 때 쓴다.
class TrialReminders {
  TrialReminders._();

  static const twoDaysBefore = '프리미엄 체험이 이틀 뒤 끝나요. 계속 쓰려면 그대로 두시면 돼요.';
  static const oneDayBefore = '내일 체험이 끝나요. 해지는 Google Play 구독 관리에서.';
  static const hour = 20;

  /// [startedAt] 기준으로 알림 시각 2개 (5일 뒤 20:00, 6일 뒤 20:00).
  static List<DateTime> timesFor(DateTime startedAt) => [
        DateTime(startedAt.year, startedAt.month, startedAt.day + 5, hour),
        DateTime(startedAt.year, startedAt.month, startedAt.day + 6, hour),
      ];

  /// 체험 구매 성공 직후.
  static Future<void> schedule(AppServices services, {DateTime? now}) async {
    final startedAt = now ?? DateTime.now();
    final endsAt = services.premium.status.expiresAt ?? startedAt.add(const Duration(days: PremiumConfig.trialDays));
    final times = timesFor(startedAt);
    try {
      await NotificationService.instance.scheduleTrialReminders(twoDaysBefore: times[0], oneDayBefore: times[1]);
      Analytics.log('trial_reminder_scheduled', {'count': 2});
    } catch (e) {
      debugPrint('[trial] 알림 예약 실패: $e');
    }
    try {
      await services.auth.service.mergeUserDoc({'trialEndsAt': endsAt.toUtc().toIso8601String()});
    } catch (_) {}
  }

  /// 취소·만료 감지 시.
  static Future<void> cancel() async {
    try {
      await NotificationService.instance.cancelTrialReminders();
    } catch (e) {
      debugPrint('[trial] 알림 취소 실패: $e');
    }
  }
}
