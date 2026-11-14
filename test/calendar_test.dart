import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/calendar/calendar_event.dart';
import 'package:recycle_ai/features/calendar/event_store.dart';
import 'package:recycle_ai/features/classify/multi/multi_classify_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('캘린더 일정', () {
    test('JSON 왕복과 날짜 키', () {
      final e = CalendarEvent(id: 'x', title: '소파 수거', kind: EventKind.bulky, date: DateTime(2026, 11, 20, 15), remind: true, createdBy: 'u', createdByName: '엄마');
      final back = CalendarEvent.fromJson('x', e.toJson());
      expect(back.title, '소파 수거');
      expect(back.kind, EventKind.bulky);
      expect(back.date, DateTime(2026, 11, 20)); // 자정으로 정규화
      expect(back.dateKey, '2026-11-20');
      expect(back.remind, isTrue);
      expect(back.createdByName, '엄마');
    });

    test('알림은 전날 20:00, 지났으면 없음', () {
      final e = CalendarEvent(id: 'a', title: 't', kind: EventKind.other, date: DateTime(2026, 11, 20));
      expect(e.remindAt(DateTime(2026, 11, 18)), DateTime(2026, 11, 19, 20));
      expect(e.remindAt(DateTime(2026, 11, 19, 21)), isNull);
      expect(e.notificationId, greaterThanOrEqualTo(1000));
    });

    test('모르는 종류는 기타', () {
      expect(EventKind.fromKey('zzz'), EventKind.other);
      expect(EventKind.fromKey('battery').label, '폐건전지·폐형광등');
    });

    test('전국 일정은 sourceUrl(https) 없으면 버린다', () {
      expect(SpecialDay.fromJson({'date': '2026-09-06', 'title': '자원순환의 날', 'note': '', 'sourceUrl': 'http://x'}), isNull);
      expect(SpecialDay.fromJson({'date': '2026-09-06', 'title': '자원순환의 날', 'note': '', 'sourceUrl': 'https://x'})?.dateKey, '2026-09-06');
      expect(SpecialDay.fromJson({'date': 'bad', 'title': 't', 'note': '', 'sourceUrl': 'https://x'}), isNull);
    });

    test('기기 저장소: 추가·조회·삭제, 재시작 후 유지', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = EventStore(prefs);
      await store.add(title: '폐건전지 배출', kind: EventKind.battery, date: DateTime(2026, 11, 21), remind: false);
      await store.add(title: '소파', kind: EventKind.bulky, date: DateTime(2026, 11, 22), remind: false);
      expect(store.events.length, 2);
      expect(store.onDay(DateTime(2026, 11, 21)).single.title, '폐건전지 배출');
      expect(store.onDay(DateTime(2026, 11, 23)), isEmpty);
      final again = EventStore(prefs);
      expect(again.events.length, 2);
      await again.remove(again.events.first.id);
      expect(again.events.length, 1);
      expect(EventStore(prefs).events.length, 1);
    });
  });

  group('여러 장 분류', () {
    test('허용 장수: 가족 플랜 10장, 무료는 남은 한도', () {
      expect(MultiClassifyScreen.allowance(premium: true, usedToday: 9), 10);
      expect(MultiClassifyScreen.allowance(premium: false, usedToday: 0), 10);
      expect(MultiClassifyScreen.allowance(premium: false, usedToday: 7), 3);
      expect(MultiClassifyScreen.allowance(premium: false, usedToday: 12), 0);
    });
  });
}
