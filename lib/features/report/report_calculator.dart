import '../../models/waste_group.dart';
import '../history/history_record.dart';
import '../schedule/pickup_schedule.dart';
import '../stats/stats_calculator.dart';
import '../tips/tips_repository.dart';
import 'carbon_factors.dart';

class TopItem {
  const TopItem(this.name, this.count);
  final String name;
  final int count;
}

class UsedFactor {
  const UsedFactor({required this.label, required this.count, required this.factor});
  final String label;
  final int count;
  final CarbonFactor factor;
  double get kg => count * (factor.perItemKg ?? 0);
}

/// 탄소 절감 환산. 계수가 있는 품목만 합산한다.
class CarbonEstimate {
  const CarbonEstimate({required this.kg, required this.coveredCount, required this.totalCount, required this.used, required this.pine});

  final double kg;
  final int coveredCount;
  final int totalCount;
  final List<UsedFactor> used;
  final PineFactor? pine;

  /// 계수 있는 품목 비율 0~1.
  double get coverage => totalCount == 0 ? 0 : coveredCount / totalCount;

  /// 전체의 절반 이상이 계수로 덮일 때만 보여준다.
  bool get showable => totalCount > 0 && coverage >= 0.5 && kg > 0;

  double? get trees => pine == null || pine!.kgPerTreePerYear <= 0 ? null : kg / pine!.kgPerTreePerYear;
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.total,
    required this.prevTotal,
    required this.recycleRate,
    required this.prevRecycleRate,
    required this.counts,
    required this.topItems,
    required this.carbon,
    required this.checkinCount,
    required this.streakWeeks,
  });

  final DateTime month;
  final int total;
  final int prevTotal;
  final int? recycleRate;
  final int? prevRecycleRate;
  final Map<WasteGroup, int> counts;
  final List<TopItem> topItems;
  final CarbonEstimate carbon;
  final int checkinCount;
  final int streakWeeks;

  int? get rateChange => recycleRate == null || prevRecycleRate == null ? null : recycleRate! - prevRecycleRate!;
  int get totalChange => total - prevTotal;

  /// 재활용률이 지난달 이상(또는 비교 불가)이면 true → 리뿅이 happy. 떨어졌으면 idle.
  bool get improvedOrSame => rateChange == null || rateChange! >= 0;

  String get title => '${month.year}년 ${month.month}월 리포트';
  String get key => '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

class ReportCalculator {
  ReportCalculator._();

  static bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  static MonthlyReport build({
    required DateTime month,
    required Iterable<HistoryRecord> history,
    required Set<String> checkinDates,
    required PickupSchedule? schedule,
    required TipsRepository tips,
    required CarbonFactors factors,
  }) {
    final m = DateTime(month.year, month.month, 1);
    final prevM = DateTime(m.year, m.month - 1, 1);
    final records = history.where((r) => sameMonth(r.date, m)).toList();
    final prev = history.where((r) => sameMonth(r.date, prevM)).toList();

    final counts = StatsCalculator.countByGroup(records);
    int? rate(List<HistoryRecord> l) => l.isEmpty ? null : (l.where((r) => r.group == WasteGroup.recycle).length * 100 / l.length).round();

    // TOP3: 팁에 매칭되면 팁 이름으로 묶고, 아니면 품목명 그대로.
    final nameCounts = <String, int>{};
    for (final r in records) {
      final name = tips.findForItem(r.itemName)?.name ?? r.itemName.trim();
      nameCounts[name] = (nameCounts[name] ?? 0) + 1;
    }
    final top = nameCounts.entries.map((e) => TopItem(e.key, e.value)).toList()
      ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.name.compareTo(b.name));

    // 탄소: 계수 있는 품목만.
    final usedBy = <String, UsedFactor>{};
    var covered = 0;
    var kg = 0.0;
    for (final r in records) {
      final tip = tips.findForItem(r.itemName);
      final f = factors.lookup(tipId: tip?.id, categoryKey: r.category.key);
      final per = f?.perItemKg;
      if (f == null || per == null) continue;
      covered++;
      kg += per;
      final label = tip?.name ?? r.category.label;
      final prevUsed = usedBy[f.id];
      usedBy[f.id] = UsedFactor(label: prevUsed?.label ?? label, count: (prevUsed?.count ?? 0) + 1, factor: f);
    }

    final checkins = checkinDates.where((k) {
      final d = DateTime.tryParse(k);
      return d != null && sameMonth(d, m);
    }).length;
    final monthEnd = DateTime(m.year, m.month + 1, 0);
    final streak = StatsCalculator.weeklyStreak(checkinDates: checkinDates, schedule: schedule, now: monthEnd).weeks;

    return MonthlyReport(
      month: m,
      total: records.length,
      prevTotal: prev.length,
      recycleRate: rate(records),
      prevRecycleRate: rate(prev),
      counts: counts,
      topItems: top.take(3).toList(),
      carbon: CarbonEstimate(kg: kg, coveredCount: covered, totalCount: records.length, used: usedBy.values.toList(), pine: factors.pine),
      checkinCount: checkins,
      streakWeeks: streak,
    );
  }
}
