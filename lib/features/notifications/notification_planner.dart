import '../calendar/calendar_event.dart';
import '../schedule/pickup_schedule.dart';
import 'notification_prefs.dart';

/// 로컬 알림 시각 계산 (순수 Dart). 방해 금지는 [QuietHours.nextAllowed] 로 미룬다.
class NotificationPlanner {
  NotificationPlanner._();

  // ---- 알림 id 대역 ----
  // 100~139 전날 저녁 (PickupSchedule.notificationId), 150~189 당일 아침, 200 월간 리포트, 201 주간 리포트,
  // 210 오랜만 인사, 300·301 체험 종료, 400~ 특별 수거일, 1000~ 캘린더 일정.
  static int morningId(WasteType t, int pickupWeekday) => 150 + t.index * 10 + pickupWeekday;
  static const weeklyReportId = 201;
  static const comebackId = 210;
  static const specialDayBaseId = 400;
  static const specialDayMax = 30;

  /// [weekday](1=월…7=일) [hour]:[minute] 의 다음 시각 (지금 포함 안 함).
  static DateTime nextWeekday(DateTime now, int weekday, int hour, int minute) {
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    while (t.weekday != weekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// 전날 저녁: 수거 요일 전날 [schedule.notifyHour]:[notifyMinute], 방해 금지면 미룸.
  static DateTime eveTime(DateTime now, int pickupWeekday, PickupSchedule schedule, QuietHours quiet) =>
      quiet.nextAllowed(nextWeekday(now, PickupSchedule.reminderWeekday(pickupWeekday), schedule.notifyHour, schedule.notifyMinute));

  /// 당일 아침: 수거 요일 [prefs.morningHour]:[morningMinute], 방해 금지면 미룸.
  static DateTime morningTime(DateTime now, int pickupWeekday, NotificationPrefs prefs) =>
      prefs.quiet.nextAllowed(nextWeekday(now, pickupWeekday, prefs.morningHour, prefs.morningMinute));

  /// 주간 리포트: 다음 일요일 20:00 (지금이 일요일 20시 전이면 오늘).
  static DateTime weeklyReportTime(DateTime now, QuietHours quiet) => quiet.nextAllowed(nextWeekday(now, DateTime.sunday, 20, 0));

  /// 특별 수거일 전날 20:00. 이미 지났으면 null.
  static DateTime? specialDayTime(DateTime now, SpecialDay day, QuietHours quiet) {
    final t = quiet.nextAllowed(DateTime(day.date.year, day.date.month, day.date.day - 1, 20));
    return t.isAfter(now) ? t : null;
  }

  /// 오랜만 인사: 마지막 실행 +72h.
  static DateTime comebackTime(DateTime lastOpenedAt, QuietHours quiet) => quiet.nextAllowed(lastOpenedAt.add(const Duration(hours: 72)));

  /// 체험 종료: 시작 +5일·+6일 20:00.
  static List<DateTime> trialTimes(DateTime startedAt, QuietHours quiet) => [
        quiet.nextAllowed(DateTime(startedAt.year, startedAt.month, startedAt.day + 5, 20)),
        quiet.nextAllowed(DateTime(startedAt.year, startedAt.month, startedAt.day + 6, 20)),
      ];

  /// 그 요일에 설정된 품목 라벨 ("재활용·일반쓰레기"). 없으면 "재활용".
  static String itemsLabel(PickupSchedule? schedule, int weekday) {
    if (schedule == null) return '재활용';
    final names = [for (final t in WasteType.values) if (schedule.daysOf(t).contains(weekday)) t.label];
    return names.isEmpty ? '재활용' : names.join('·');
  }

  /// 이번 주(월~일) 시작.
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static String monthDay(DateTime d) => '${d.month}월 ${d.day}일';
}
