import '../../models/waste_group.dart';
import '../history/history_record.dart';
import '../schedule/pickup_schedule.dart';

/// 월간 요약. 전부 클라이언트에서 계산한다 (기록이 최대 500건이라 집계 쿼리보다 싸다).
class MonthlySummary {
  const MonthlySummary({
    required this.total,
    required this.counts,
    required this.recycleRate,
    required this.lastMonthRecycleRate,
  });

  final int total;
  final Map<WasteGroup, int> counts;

  /// 0~100. 기록이 없으면 null.
  final int? recycleRate;
  final int? lastMonthRecycleRate;

  /// 지난달 대비 %p. 어느 한 달이라도 기록이 없으면 null.
  int? get changePoints =>
      recycleRate == null || lastMonthRecycleRate == null ? null : recycleRate! - lastMonthRecycleRate!;
}

/// 주별 점 하나.
class WeekDot {
  const WeekDot({required this.weekStart, required this.success, required this.isCurrent});

  final DateTime weekStart;
  final bool success;
  final bool isCurrent;
}

class StreakResult {
  const StreakResult({required this.weeks, required this.dots});

  /// 연속 성공 주 수.
  final int weeks;

  /// 오래된 주부터 12개.
  final List<WeekDot> dots;
}

class StatsCalculator {
  StatsCalculator._();

  static Map<WasteGroup, int> countByGroup(Iterable<HistoryRecord> records) {
    final counts = {for (final g in WasteGroup.values) g: 0};
    for (final r in records) {
      counts[r.group] = counts[r.group]! + 1;
    }
    return counts;
  }

  static int? _recycleRate(Iterable<HistoryRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return null;
    final recycle = list.where((r) => r.group == WasteGroup.recycle).length;
    return (recycle * 100 / list.length).round();
  }

  static bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  static MonthlySummary monthlySummary(Iterable<HistoryRecord> all, DateTime now) {
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final thisMonth = all.where((r) => _sameMonth(r.date, now)).toList();
    final prev = all.where((r) => _sameMonth(r.date, lastMonth));
    return MonthlySummary(
      total: thisMonth.length,
      counts: countByGroup(thisMonth),
      recycleRate: _recycleRate(thisMonth),
      lastMonthRecycleRate: _recycleRate(prev),
    );
  }

  /// 월요일 00:00 로 내린다.
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// 주간 스트릭.
  ///
  /// - 한 주(월~일)에 설정된 수거일이 있고, 그 주에 체크인이 하나라도 있으면 성공.
  /// - 이번 주는 아직 진행 중이라 체크가 없어도 스트릭을 끊지 않는다 (체크가 있으면 포함).
  /// - 수거일 설정이 없으면 스트릭 0.
  static StreakResult weeklyStreak({
    required Set<String> checkinDates,
    required PickupSchedule? schedule,
    required DateTime now,
    int weeksToShow = 12,
  }) {
    final configuredDays = <int>{for (final t in WasteType.values) ...(schedule?.daysOf(t) ?? const {})};
    final current = weekStart(now);
    final checked = <DateTime>{};
    for (final key in checkinDates) {
      final d = DateTime.tryParse(key);
      if (d != null) checked.add(weekStart(d));
    }

    final dots = <WeekDot>[];
    for (var i = weeksToShow - 1; i >= 0; i--) {
      final ws = current.subtract(Duration(days: 7 * i));
      final success = configuredDays.isNotEmpty && checked.contains(ws);
      dots.add(WeekDot(weekStart: ws, success: success, isCurrent: i == 0));
    }

    var streak = 0;
    if (configuredDays.isNotEmpty) {
      var ws = current;
      // 이번 주에 체크가 없으면 지난주부터 센다.
      if (!checked.contains(ws)) ws = ws.subtract(const Duration(days: 7));
      while (checked.contains(ws)) {
        streak++;
        ws = ws.subtract(const Duration(days: 7));
      }
    }
    return StreakResult(weeks: streak, dots: dots);
  }
}
