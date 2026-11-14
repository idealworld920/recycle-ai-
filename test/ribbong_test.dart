import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/mascot/guide_steps.dart';
import 'package:recycle_ai/features/mascot/home_ribbong.dart';
import 'package:recycle_ai/features/mascot/ribbong_lines.dart';
import 'package:recycle_ai/features/schedule/pickup_schedule.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('리뿅이 대사', () {
    test('조건 우선순위: 당일 > 전날 > 3일 복귀 > 10개 > 시간대', () {
      final noon = DateTime(2026, 11, 14, 12);
      final old = noon.subtract(const Duration(days: 4));
      expect(RibbongLines.decide(now: noon, todayPickups: [WasteType.recycle], tomorrowPickups: [WasteType.food], lastOpenedAt: old, classifiedToday: 12), LineWhen.pickupToday);
      expect(RibbongLines.decide(now: noon, todayPickups: [], tomorrowPickups: [WasteType.food], lastOpenedAt: old, classifiedToday: 12), LineWhen.pickupTomorrow);
      expect(RibbongLines.decide(now: noon, todayPickups: [], tomorrowPickups: [], lastOpenedAt: old, classifiedToday: 12), LineWhen.returnAfter3Days);
      expect(RibbongLines.decide(now: noon, todayPickups: [], tomorrowPickups: [], lastOpenedAt: noon, classifiedToday: 12), LineWhen.classified10);
      expect(RibbongLines.decide(now: DateTime(2026, 11, 14, 8), todayPickups: [], tomorrowPickups: [], lastOpenedAt: null, classifiedToday: 0), LineWhen.morning);
      expect(RibbongLines.decide(now: noon, todayPickups: [], tomorrowPickups: [], lastOpenedAt: null, classifiedToday: 0), LineWhen.day);
      expect(RibbongLines.decide(now: DateTime(2026, 11, 14, 19), todayPickups: [], tomorrowPickups: [], lastOpenedAt: null, classifiedToday: 0), LineWhen.evening);
      expect(RibbongLines.decide(now: DateTime(2026, 11, 14, 23), todayPickups: [], tomorrowPickups: [], lastOpenedAt: null, classifiedToday: 0), LineWhen.night);
    });

    test('파일 형식 세 가지 모두 읽고, 없으면 내장 문장, {type} 치환, 뿅으로 끝남', () {
      final a = RibbongLines.fromJsonString('["안녕이뿅", "반갑뿅"]');
      expect(a.count, 2);
      final b = RibbongLines.fromJsonString('{"lines":[{"text":"아침이뿅","when":"morning"},{"text":"그냥뿅"}]}');
      expect(b.linesFor(LineWhen.morning), ['아침이뿅']);
      expect(b.linesFor(LineWhen.random), ['그냥뿅']);
      // 실제 파일 형식: condition 별칭
      final d = RibbongLines.fromJsonString(
          '[{"id":"x1","condition":"collection_today","text":"출동이뿅!"},{"id":"x2","condition":"comeback","text":"오랜만이뿅!"},{"id":"x3","condition":"busy_day","text":"바쁘뿅!"},{"id":"x4","condition":"afternoon","text":"오후뿅"},{"id":"x5","condition":"없는조건","text":"그냥뿅"}]');
      expect(d.linesFor(LineWhen.pickupToday), ['출동이뿅!']);
      expect(d.linesFor(LineWhen.returnAfter3Days), ['오랜만이뿅!']);
      expect(d.linesFor(LineWhen.classified10), ['바쁘뿅!']);
      expect(d.linesFor(LineWhen.day), ['오후뿅']);
      expect(d.linesFor(LineWhen.random), ['그냥뿅']);
      final c = RibbongLines.fromJsonString('{"night":["밤이뿅"]}');
      expect(c.linesFor(LineWhen.night), ['밤이뿅']);
      expect(c.linesFor(LineWhen.day), RibbongLines.builtIn[LineWhen.day]);
      final line = RibbongLines(const {}).pick(LineWhen.pickupToday, types: [WasteType.recycle], rnd: Random(1));
      expect(line, contains('재활용'));
      expect(line.trim().endsWith('뿅!') || line.trim().endsWith('뿅.') || line.trim().endsWith('뿅~') || line.trim().endsWith('뿅'), isTrue);
      for (final w in LineWhen.values) {
        for (final l in RibbongLines.builtIn[w]!) {
          expect(l.contains('뿅'), isTrue, reason: l);
        }
      }
    });
  });

  group('실제 ribbong_lines.json', () {
    testWidgets('30개 전부 읽히고 조건별로 들어간다 (random 으로 새는 것 없음)', (tester) async {
      final lines = await RibbongLines.load();
      expect(lines.count, 30);
      expect(lines.linesFor(LineWhen.pickupToday).length, 5);
      expect(lines.linesFor(LineWhen.pickupTomorrow).length, 4);
      expect(lines.linesFor(LineWhen.returnAfter3Days).length, 3);
      expect(lines.linesFor(LineWhen.classified10).length, 3);
      for (final w in [LineWhen.morning, LineWhen.day, LineWhen.evening, LineWhen.night, LineWhen.random]) {
        expect(lines.linesFor(w).length, 3, reason: w.name);
      }
      for (final w in LineWhen.values) {
        for (final l in lines.linesFor(w)) {
          expect(l.contains('뿅'), isTrue, reason: l);
        }
      }
    });
  });

  group('7일 가이드', () {
    test('경과일·미설정 기준으로 하나씩, 설정됐거나 닫았으면 건너뜀', () {
      GuideStep? at(int day, {bool sched = false, bool region = false, bool premium = false, Set<String> dismissed = const {}}) =>
          GuideStep.current(daysSinceInstall: day, hasSchedule: sched, hasRegion: region, isPremium: premium, dismissed: dismissed);
      expect(at(1), isNull);
      expect(at(2), GuideStep.schedule);
      expect(at(3, sched: true), isNull);
      expect(at(4), GuideStep.region);
      expect(at(5, region: true), isNull);
      expect(at(6), GuideStep.premium);
      expect(at(7, premium: true), isNull);
      expect(at(7, dismissed: {'premium'}), isNull);
      expect(at(2, dismissed: {'schedule'}), isNull); // X 누른 뒤 재진입: 같은 가이드는 다시 안 뜬다
      expect(at(4, dismissed: {'schedule'}), GuideStep.region); // 다음 단계는 뜬다
      expect(at(8), isNull);
      expect(GuideStep.premium.actionLabel, '자세히');
      expect(GuideStep.schedule.actionLabel, '설정하기');
      expect(GuideStep.schedule.line, '수거일 알려주면 전날에 챙겨주겠뿅!');
      expect(GuideStep.region.line, '우리 동네 어디뿅? 동네 기준으로 알려주겠뿅!');
      expect(GuideStep.premium.line, '프리미엄 써보면 더 편하뿅!');
    });
  });

  group('홈 리뿅이', () {
    test('도감 뱃지 10/30/50', () {
      expect(HomeRibbong.collectionBadge(9), isNull);
      expect(HomeRibbong.collectionBadge(10), '🌱');
      expect(HomeRibbong.collectionBadge(30), '🌿');
      expect(HomeRibbong.collectionBadge(50), '🌳');
    });

    test('설정 저장소: 직전 실행 시각·가이드 닫기·첫 분류 플래그', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsStore.load();
      expect(s.previousOpenedAt, isNull);
      await s.markOpened();
      expect(s.previousOpenedAt, isNull); // 첫 실행: 직전 기록 없음
      await s.markOpened();
      expect(s.previousOpenedAt, isNotNull);
      Map<String, dynamic>? sent;
      await s.dismissGuide('schedule', remote: (m) async => sent = m);
      expect(s.guideDismissed, {'schedule'});
      expect((sent!['guide'] as Map)['dismissed'], ['schedule']);
      expect((sent!['guide'] as Map)['installedAt'], isA<String>());
      expect(s.firstClassifyDone, isFalse);
      await s.markFirstClassifyDone();
      expect(s.firstClassifyDone, isTrue);
    });
  });
}
