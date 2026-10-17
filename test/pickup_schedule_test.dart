import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/schedule/pickup_schedule.dart';

void main() {
  // 2026-10-14 는 수요일.
  final wed = DateTime(2026, 10, 14, 9);
  final schedule = PickupSchedule(days: {
    WasteType.recycle: {3, 6}, // 수, 토
    WasteType.general: {1, 4}, // 월, 목
    WasteType.food: {2}, // 화
  });

  test('오늘이 수거일이면 D-Day', () {
    final n = schedule.next(WasteType.recycle, wed)!;
    expect(n.daysUntil, 0);
    expect(n.isToday, isTrue);
    expect(n.dDayLabel, 'D-Day');
    expect(schedule.todayTypes(wed), [WasteType.recycle]);
  });

  test('다음 수거일과 D-day 계산', () {
    expect(schedule.next(WasteType.general, wed)!.daysUntil, 1); // 목
    expect(schedule.next(WasteType.food, wed)!.daysUntil, 6); // 다음 화
    expect(schedule.next(WasteType.general, wed)!.dDayLabel, 'D-1');
  });

  test('가까운 순 정렬, 오늘 제외 옵션', () {
    final all = schedule.upcoming(wed);
    expect(all.map((e) => e.type), [WasteType.recycle, WasteType.general, WasteType.food]);
    final noToday = schedule.upcoming(wed, includeToday: false);
    expect(noToday.first.type, WasteType.general);
    expect(noToday.map((e) => e.type), contains(WasteType.recycle)); // 토요일 것
    expect(noToday.firstWhere((e) => e.type == WasteType.recycle).daysUntil, 3);
  });

  test('설정 안 된 종류는 null, 전체 비었는지 판단', () {
    expect(const PickupSchedule().next(WasteType.recycle, wed), isNull);
    expect(const PickupSchedule().isEmpty, isTrue);
    expect(schedule.isConfigured, isTrue);
  });

  test('알림은 수거 전날 요일, 월요일 수거면 일요일', () {
    expect(PickupSchedule.reminderWeekday(1), 7);
    expect(PickupSchedule.reminderWeekday(3), 2);
    expect(PickupSchedule.notificationId(WasteType.recycle, 3), 103);
    expect(PickupSchedule.notificationId(WasteType.food, 7), 127);
  });

  test('요일 토글과 JSON 왕복', () {
    final toggled = schedule.toggleDay(WasteType.food, 5).toggleDay(WasteType.food, 2);
    expect(toggled.daysOf(WasteType.food), {5});
    final restored = PickupSchedule.fromJson(toggled.copyWith(notifyHour: 19, notifyMinute: 30).toJson());
    expect(restored.daysOf(WasteType.recycle), {3, 6});
    expect(restored.daysOf(WasteType.food), {5});
    expect(restored.notifyTimeLabel, '19:30');
  });

  test('기본 알림 시각은 20:00', () {
    expect(const PickupSchedule().notifyTimeLabel, '20:00');
  });
}
