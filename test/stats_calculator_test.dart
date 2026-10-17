import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/schedule/pickup_schedule.dart';
import 'package:recycle_ai/features/stats/stats_calculator.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/waste_group.dart';

HistoryRecord _r(String id, RecycleCategory c, DateTime d) =>
    HistoryRecord(id: id, date: d, itemName: id, category: c);

void main() {
  final now = DateTime(2026, 10, 17, 12); // 토요일

  group('monthlySummary', () {
    test('이번 달 건수·재활용 비율·지난달 대비', () {
      final records = [
        _r('a', RecycleCategory.pet, DateTime(2026, 10, 3)),
        _r('b', RecycleCategory.can, DateTime(2026, 10, 5)),
        _r('c', RecycleCategory.general, DateTime(2026, 10, 9)),
        _r('d', RecycleCategory.food, DateTime(2026, 10, 12)),
        // 지난달: 재활용 1 / 2 = 50%
        _r('e', RecycleCategory.paper, DateTime(2026, 9, 20)),
        _r('f', RecycleCategory.general, DateTime(2026, 9, 21)),
      ];
      final s = StatsCalculator.monthlySummary(records, now);
      expect(s.total, 4);
      expect(s.recycleRate, 50);
      expect(s.counts[WasteGroup.recycle], 2);
      expect(s.counts[WasteGroup.food], 1);
      expect(s.lastMonthRecycleRate, 50);
      expect(s.changePoints, 0);
    });

    test('지난달 기록이 없으면 변화는 null', () {
      final s = StatsCalculator.monthlySummary([_r('a', RecycleCategory.pet, DateTime(2026, 10, 3))], now);
      expect(s.recycleRate, 100);
      expect(s.changePoints, isNull);
    });

    test('기록이 없으면 비율 null', () {
      expect(StatsCalculator.monthlySummary(const [], now).recycleRate, isNull);
    });
  });

  group('weeklyStreak', () {
    final schedule = PickupSchedule(days: {WasteType.recycle: {3}});

    test('이번 주 체크 없어도 지난주부터 연속이면 유지', () {
      // 이번 주 월요일은 10/12. 지난 3주 수요일마다 체크.
      final r = StatsCalculator.weeklyStreak(
        checkinDates: {'2026-10-07', '2026-09-30', '2026-09-23'},
        schedule: schedule,
        now: now,
      );
      expect(r.weeks, 3);
      expect(r.dots.length, 12);
      expect(r.dots.last.isCurrent, isTrue);
      expect(r.dots.last.success, isFalse);
      expect(r.dots[r.dots.length - 2].success, isTrue);
    });

    test('이번 주 체크하면 포함', () {
      final r = StatsCalculator.weeklyStreak(
        checkinDates: {'2026-10-14', '2026-10-07'},
        schedule: schedule,
        now: now,
      );
      expect(r.weeks, 2);
      expect(r.dots.last.success, isTrue);
    });

    test('중간에 빠진 주가 있으면 거기서 끊긴다', () {
      final r = StatsCalculator.weeklyStreak(
        checkinDates: {'2026-10-14', '2026-09-30'},
        schedule: schedule,
        now: now,
      );
      expect(r.weeks, 1);
    });

    test('수거일 설정이 없으면 0', () {
      final r = StatsCalculator.weeklyStreak(checkinDates: {'2026-10-14'}, schedule: null, now: now);
      expect(r.weeks, 0);
      expect(r.dots.every((d) => !d.success), isTrue);
    });
  });
}
