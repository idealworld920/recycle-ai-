import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/calendar/calendar_event.dart';
import 'package:recycle_ai/features/notifications/notification_background.dart';
import 'package:recycle_ai/features/notifications/notification_lines.dart';
import 'package:recycle_ai/features/notifications/notification_planner.dart';
import 'package:recycle_ai/features/notifications/notification_prefs.dart';
import 'package:recycle_ai/features/schedule/notification_service.dart';
import 'package:recycle_ai/features/schedule/pickup_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('방해 금지 시간', () {
    const q = QuietHours(); // 22:00~07:00
    test('자정 넘는 구간 판정과 다음 허용 시각', () {
      expect(q.contains(DateTime(2026, 11, 17, 23)), isTrue);
      expect(q.contains(DateTime(2026, 11, 17, 3)), isTrue);
      expect(q.contains(DateTime(2026, 11, 17, 7)), isFalse);
      expect(q.contains(DateTime(2026, 11, 17, 21, 59)), isFalse);
      expect(q.nextAllowed(DateTime(2026, 11, 17, 23, 30)), DateTime(2026, 11, 18, 7));
      expect(q.nextAllowed(DateTime(2026, 11, 17, 2)), DateTime(2026, 11, 17, 7));
      expect(q.nextAllowed(DateTime(2026, 11, 17, 20)), DateTime(2026, 11, 17, 20));
    });
    test('자정을 안 넘는 구간(13:00~15:00)과 빈 구간', () {
      const day = QuietHours(startMinutes: 13 * 60, endMinutes: 15 * 60);
      expect(day.contains(DateTime(2026, 1, 1, 14)), isTrue);
      expect(day.nextAllowed(DateTime(2026, 1, 1, 14)), DateTime(2026, 1, 1, 15));
      const none = QuietHours(startMinutes: 60, endMinutes: 60);
      expect(none.contains(DateTime(2026, 1, 1, 1)), isFalse);
    });
    test('끄면 아무것도 미루지 않는다 + JSON 에 enabled 유지', () {
      const off = QuietHours(enabled: false);
      expect(off.contains(DateTime(2026, 1, 1, 23)), isFalse);
      expect(off.nextAllowed(DateTime(2026, 1, 1, 23)), DateTime(2026, 1, 1, 23));
      final back = QuietHours.fromJson(off.toJson());
      expect(back.enabled, isFalse);
      expect(QuietHours.fromJson({'start': 1320, 'end': 420}).enabled, isTrue); // 옛 문서(enabled 없음)는 켜진 것으로
      expect(off.copyWith(enabled: true).contains(DateTime(2026, 1, 1, 23)), isTrue);
    });
    test('JSON 왕복', () {
      final p = const NotificationPrefs(enabled: {NotificationType.weeklyReport: false}, morningHour: 8, morningMinute: 15, quiet: QuietHours(startMinutes: 1380, endMinutes: 360));
      final back = NotificationPrefs.fromJson(p.toJson());
      expect(back.isOn(NotificationType.weeklyReport), isFalse);
      expect(back.isOn(NotificationType.pickupEve), isTrue);
      expect(back.morningLabel, '08:15');
      expect(back.quiet.label, '23:00~06:00');
    });
  });

  group('시각 계산', () {
    final tue = DateTime(2026, 11, 17, 12); // 화요일
    final schedule = PickupSchedule(days: {WasteType.recycle: {3}, WasteType.food: {3, 6}}, notifyHour: 20, notifyMinute: 0);
    test('전날 저녁·당일 아침·주간 리포트', () {
      expect(NotificationPlanner.eveTime(tue, 3, schedule, const QuietHours()), DateTime(2026, 11, 17, 20)); // 수요일 수거 → 화요일 20:00
      final prefs = const NotificationPrefs(morningHour: 7, morningMinute: 30);
      expect(NotificationPlanner.morningTime(tue, 3, prefs), DateTime(2026, 11, 18, 7, 30));
      // 방해 금지 안의 시각(23:00)은 07:00 으로 미룬다
      final late = PickupSchedule(days: {WasteType.recycle: {3}}, notifyHour: 23, notifyMinute: 0);
      expect(NotificationPlanner.eveTime(tue, 3, late, const QuietHours()), DateTime(2026, 11, 18, 7));
      expect(NotificationPlanner.weeklyReportTime(tue, const QuietHours()), DateTime(2026, 11, 22, 20));
      expect(NotificationPlanner.weeklyReportTime(DateTime(2026, 11, 22, 21), const QuietHours()), DateTime(2026, 11, 29, 20));
    });
    test('특별 수거일 전날 20:00, 지났으면 null, 지역 매칭', () {
      final day = SpecialDay(date: DateTime(2026, 12, 25), title: '성탄절', note: '', sourceUrl: 'https://x', region: '서울');
      expect(NotificationPlanner.specialDayTime(tue, day, const QuietHours()), DateTime(2026, 12, 24, 20));
      expect(NotificationPlanner.specialDayTime(DateTime(2026, 12, 26), day, const QuietHours()), isNull);
      expect(day.appliesTo(regionCode: '11440', sido: '서울'), isTrue);
      expect(day.appliesTo(regionCode: '41110', sido: '경기'), isFalse);
      expect(SpecialDay(date: DateTime(2026, 1, 1), title: '', note: '', sourceUrl: 'https://x').appliesTo(regionCode: null, sido: null), isTrue);
    });
    test('오랜만 +72h, 체험 +5/+6일 20:00, 품목 라벨', () {
      expect(NotificationPlanner.comebackTime(DateTime(2026, 11, 17, 23), const QuietHours()), DateTime(2026, 11, 21, 7)); // 20일 23시 → 방해 금지 → 21일 07시
      expect(NotificationPlanner.trialTimes(DateTime(2026, 11, 17, 9), const QuietHours()), [DateTime(2026, 11, 22, 20), DateTime(2026, 11, 23, 20)]);
      expect(NotificationPlanner.itemsLabel(schedule, 3), '재활용·음식물');
      expect(NotificationPlanner.itemsLabel(schedule, 1), '재활용');
      expect(NotificationPlanner.itemsLabel(null, 1), '재활용');
    });
  });

  group('문구', () {
    test('내장 문구: 종류마다 제목 + 본문, 치환, 이모지 없음, 뿅체', () {
      final l = NotificationLines(NotificationLines.builtIn);
      for (final key in l.keys) {
        expect(l.title(key), isNotEmpty, reason: key);
        expect(l.bodies(key), isNotEmpty, reason: key);
        for (final b in l.bodies(key)) {
          expect(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true).hasMatch(b), isFalse, reason: b);
          if (!key.startsWith('trialEnd')) expect(b.contains('뿅'), isTrue, reason: b);
        }
      }
      expect(l.body('pickupEve', vars: {'품목': '재활용'}, index: 0), '내일 재활용 수거일이뿅! 미리 모아두면 아침이 편하뿅');
      expect(l.title('familyCheckin', vars: {'이름': '민수'}), '민수님이 버렸뿅');
      expect(l.body('weeklyReport', vars: {'N': '7', 'M': '71'}, index: 0), '이번 주 7개 분류했뿅! 재활용 71%뿅. 대단하뿅');
      expect(l.body('trialEndD2'), contains('돼요')); // 표준 존댓말
    });
    test('실제 JSON 파일 로드', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final l = await NotificationLines.load();
      expect(l.bodies('pickupMorning').length, 3);
      expect(l.bodies('specialDay').length, 3);
      expect(NotificationLines.checkinAction, '버렸뿅!');
    });
  });

  group('알림 payload·액션', () {
    test('payload 에 품목을 붙이고 base 로 종류·동작을 고른다', () {
      final p = NotificationPayloads.withType(NotificationPayloads.pickupMorning, WasteType.food);
      expect(p, 'pickup_morning:food');
      expect(NotificationPayloads.typeOf(p), 'pickup_morning');
      expect(NotificationPayloads.appAction(p), 'home');
      expect(NotificationPayloads.appAction(NotificationPayloads.weeklyReport), 'report');
      expect(NotificationPayloads.typeOf('premium'), 'trial_end');
    });
    test('[버렸뿅!] 액션: 아침 → 오늘, 전날 → 내일, 명시 payload', () {
      final now = DateTime(2026, 11, 17, 8);
      expect(NotificationActions.parseCheckin('pickup_morning:recycle', now: now), (WasteType.recycle, '2026-11-17'));
      expect(NotificationActions.parseCheckin('pickup_eve:food', now: now), (WasteType.food, '2026-11-18'));
      expect(NotificationActions.parseCheckin('checkin:general:2026-11-01'), (WasteType.general, '2026-11-01'));
      expect(NotificationActions.parseCheckin('weekly_report'), isNull);
    });
    test('백그라운드 체크인 큐', () async {
      SharedPreferences.setMockInitialValues({});
      final q = PendingCheckins(await SharedPreferences.getInstance());
      await q.add('2026-11-17', WasteType.recycle);
      await q.add('2026-11-17', WasteType.recycle); // 중복 무시
      await q.add('2026-11-18', WasteType.food);
      expect(q.all, [('2026-11-17', WasteType.recycle), ('2026-11-18', WasteType.food)]);
      await q.clear();
      expect(q.all, isEmpty);
    });
  });

  group('알림 설정 저장소', () {
    test('토글·시각·방해 금지 저장 + onChanged 호출', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = NotificationPrefsStore(prefs);
      var changed = 0;
      store.onChanged = () async => changed++;
      expect(store.isOn(NotificationType.familyReminder), isTrue);
      await store.setEnabled(NotificationType.familyReminder, false);
      await store.setMorningTime(6, 45);
      await store.setQuietHours(const QuietHours(startMinutes: 23 * 60, endMinutes: 8 * 60));
      await store.setQuietEnabled(false);
      expect(changed, 4);
      final again = NotificationPrefsStore(prefs);
      expect(again.isOn(NotificationType.familyReminder), isFalse);
      expect(again.value.morningLabel, '06:45');
      expect(again.value.quiet.label, '23:00~08:00');
      expect(again.value.quiet.enabled, isFalse);
    });
  });
}
