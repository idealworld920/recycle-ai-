import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/models/waste_group.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/recycle_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecycleResult _result(String name, RecycleCategory c, DateTime at) => RecycleResult(
      itemName: name,
      category: c,
      confidence: 0.9,
      steps: const ['헹구기', '배출하기'],
      warnings: const [],
      tip: '',
      createdAt: at,
    );

void main() {
  late HistoryStore store;
  final now = DateTime(2026, 10, 17, 12, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await HistoryStore.load();
  });

  test('분류 결과를 저장하고 다시 읽는다', () async {
    await store.addResult(_result('생수 페트병', RecycleCategory.pet, now));
    final reloaded = await HistoryStore.load();
    expect(reloaded.items.single.itemName, '생수 페트병');
    expect(reloaded.items.single.category, RecycleCategory.pet);
    expect(reloaded.items.single.toResult().steps.length, 2);
  });

  test('2분 안에 같은 품목·분류는 중복 저장하지 않는다', () async {
    final a = await store.addResult(_result('캔', RecycleCategory.can, now));
    final b = await store.addResult(_result('캔', RecycleCategory.can, now.add(const Duration(seconds: 30))));
    expect(b.id, a.id);
    expect(store.items.length, 1);

    await store.addResult(_result('캔', RecycleCategory.can, now.add(const Duration(minutes: 5))));
    expect(store.items.length, 2);
  });

  test('500건을 넘으면 오래된 것부터 지운다', () async {
    for (var i = 0; i < 505; i++) {
      await store.addRecord(HistoryRecord(
        id: 'r$i',
        date: now.subtract(Duration(hours: i)),
        itemName: '항목 $i',
        category: RecycleCategory.paper,
      ));
    }
    expect(store.items.length, HistoryStore.maxItems);
    expect(store.items.first.id, 'r0');
    expect(store.items.any((r) => r.id == 'r504'), isFalse);
  });

  test('삭제와 전체 삭제', () async {
    final r = await store.addResult(_result('유리병', RecycleCategory.glass, now));
    await store.addResult(_result('비닐', RecycleCategory.vinyl, now.subtract(const Duration(days: 1))));
    await store.remove(r.id);
    expect(store.items.map((e) => e.itemName), ['비닐']);
    await store.clear();
    expect(store.items, isEmpty);
  });

  test('이번 달 요약과 그룹별 건수', () async {
    await store.addResult(_result('페트병', RecycleCategory.pet, now));
    await store.addResult(_result('치킨 뼈', RecycleCategory.general, now.subtract(const Duration(days: 2))));
    await store.addResult(_result('바나나 껍질', RecycleCategory.food, now.subtract(const Duration(days: 3))));
    await store.addResult(_result('건전지', RecycleCategory.hazardous, now.subtract(const Duration(days: 4))));
    await store.addResult(_result('지난달 캔', RecycleCategory.can, DateTime(2026, 9, 20)));

    final month = store.inMonth(now);
    expect(month.length, 4);
    final counts = HistoryStore.countByGroup(month);
    expect(counts[WasteGroup.recycle], 1);
    expect(counts[WasteGroup.general], 1);
    expect(counts[WasteGroup.food], 1);
    expect(counts[WasteGroup.special], 1);
  });

  test('날짜별 그룹은 최신 날짜가 먼저', () async {
    await store.addResult(_result('A', RecycleCategory.pet, now.subtract(const Duration(days: 1))));
    await store.addResult(_result('B', RecycleCategory.can, now));
    await store.addResult(_result('C', RecycleCategory.paper, now.subtract(const Duration(hours: 1))));
    final groups = HistoryStore.groupByDay(store.items);
    expect(groups.length, 2);
    expect(groups.first.$1, DateTime(2026, 10, 17));
    expect(groups.first.$2.map((r) => r.itemName), ['B', 'C']);
  });
}
