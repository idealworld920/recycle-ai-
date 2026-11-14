import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/core/boot_report.dart';
import 'package:recycle_ai/core/firebase_session.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/auth_service.dart';
import 'package:recycle_ai/features/auth/auth_store.dart';
import 'package:recycle_ai/features/calendar/event_store.dart';
import 'package:recycle_ai/features/feedback/feedback_store.dart';
import 'package:recycle_ai/features/history/delete_records.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/history/history_screen.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/mascot/home_ribbong.dart';
import 'package:recycle_ai/features/places/region.dart';
import 'package:recycle_ai/features/places/region_store.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:recycle_ai/features/report/carbon_factors.dart';
import 'package:recycle_ai/features/schedule/schedule_store.dart';
import 'package:recycle_ai/features/stats/collection_store.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _tipsJson(int n) => jsonEncode({
      'items': [
        {'id': 'pet', 'name': '페트병', 'aliases': ['생수 페트병'], 'category': '재활용', 'steps': ['헹궈요']},
        {'id': 'can', 'name': '캔', 'category': '재활용', 'steps': ['비워요']},
        {'id': 'box', 'name': '택배 상자', 'category': '재활용', 'steps': ['펼쳐요']},
        for (var i = 0; i < n; i++) {'id': 'extra$i', 'name': '품목$i', 'category': '일반쓰레기', 'steps': []},
      ],
    });

HistoryRecord _rec(String id, String name, RecycleCategory c, DateTime at) =>
    HistoryRecord(id: id, date: at, itemName: name, category: c, detail: const {'confidence': 0.9, 'steps': [], 'warnings': [], 'tip': ''});

void main() {
  final now = DateTime.now();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('도감 재계산', () {
    test('같은 품목이 다른 기록에 남아 있으면 도감 유지, 하나도 없으면 제거', () async {
      final tips = TipsRepository.fromJsonString(_tipsJson(0));
      final history = await HistoryStore.load();
      final collection = await CollectionStore.load(tips);
      final a = await history.addRecord(_rec('a', '생수 페트병', RecycleCategory.pet, now));
      final b = await history.addRecord(_rec('b', '페트병', RecycleCategory.pet, now.subtract(const Duration(hours: 2))));
      final c = await history.addRecord(_rec('c', '캔', RecycleCategory.can, now.subtract(const Duration(days: 1))));
      await history.addRecord(_rec('d', '알 수 없는 물건', RecycleCategory.unknown, now.subtract(const Duration(days: 2))));
      for (final name in ['생수 페트병', '캔']) {
        await collection.collect(tips.findForItem(name)!);
      }
      expect(collection.collectedIds, {'pet', 'can'});

      // a 삭제: b 가 같은 pet 이라 유지
      var removed = await history.removeMany([a.id]);
      var dropped = await RecordDeleter.reconcileCollection(collection, tips, removed: removed, remaining: history.items);
      expect(dropped, isEmpty);
      expect(collection.collectedIds, {'pet', 'can'});

      // b + c 삭제: pet·can 둘 다 남은 기록 없음 → 제거
      removed = await history.removeMany([b.id, c.id]);
      dropped = await RecordDeleter.reconcileCollection(collection, tips, removed: removed, remaining: history.items);
      expect(dropped, {'pet', 'can'});
      expect(collection.collectedIds, isEmpty);
      // 기기 저장도 맞춰진다
      expect((await CollectionStore.load(tips)).collectedIds, isEmpty);

      // 팁에 없는 품목 삭제는 도감에 영향 없음
      removed = await history.removeMany(['d']);
      expect(await RecordDeleter.reconcileCollection(collection, tips, removed: removed, remaining: history.items), isEmpty);
    });

    test('도감이 10개 아래로 내려가면 뱃지가 조용히 사라진다 (개수로 즉시 계산)', () async {
      final tips = TipsRepository.fromJsonString(_tipsJson(8));
      final history = await HistoryStore.load();
      final collection = await CollectionStore.load(tips);
      // 10개 수집 (pet, can + extra0..7), 기록은 각 1건
      await history.addRecord(_rec('p', '페트병', RecycleCategory.pet, now));
      await history.addRecord(_rec('c', '캔', RecycleCategory.can, now));
      for (var i = 0; i < 8; i++) {
        await history.addRecord(_rec('e$i', '품목$i', RecycleCategory.general, now.subtract(Duration(minutes: i + 1))));
      }
      for (final r in history.items) {
        await collection.collect(tips.findForItem(r.itemName)!);
      }
      expect(collection.collected, 10);
      expect(HomeRibbong.collectionBadge(collection.collected), '🌱');
      final removed = await history.removeMany(['p']);
      await RecordDeleter.reconcileCollection(collection, tips, removed: removed, remaining: history.items);
      expect(collection.collected, 9);
      expect(HomeRibbong.collectionBadge(collection.collected), isNull);
    });
  });

  group('기록 선택 삭제 화면', () {
    late HistoryStore history;
    late CollectionStore collection;

    Future<void> pump(WidgetTester tester) async {
      // 요약 카드 아래에 목록이 오므로 긴 화면으로 (스크롤 없이 전부 보이게).
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final tips = TipsRepository.fromJsonString(_tipsJson(0));
      history = await HistoryStore.load();
      collection = await CollectionStore.load(tips);
      await history.addRecord(_rec('a', '생수 페트병', RecycleCategory.pet, now.subtract(const Duration(minutes: 5))));
      await history.addRecord(_rec('b', '캔', RecycleCategory.can, now.subtract(const Duration(minutes: 30))));
      await history.addRecord(_rec('c', '택배 상자', RecycleCategory.paper, now.subtract(const Duration(days: 3))));
      for (final r in history.items) {
        await collection.collect(tips.findForItem(r.itemName)!);
      }
      await tester.pumpWidget(AppServices(
        settings: await SettingsStore.load(),
        history: history,
        tips: tips,
        firebase: FirebaseSession.unavailable(),
        schedule: await ScheduleStore.load(),
        collection: collection,
        region: await RegionStore.load(RegionRepository.fromJsonString('{"items":[]}')),
        auth: await AuthStore.load(OfflineAuthService()),
        premium: PremiumStore(PurchasesService.instance),
        household: HouseholdStore(HouseholdRepository()),
        events: EventStore(await SharedPreferences.getInstance()),
        freeLimits: FreeLimits(await SharedPreferences.getInstance()),
        boot: BootReport(),
        feedback: FeedbackStore(await SharedPreferences.getInstance()),
        carbon: const CarbonFactors(factors: {}, pine: null),
        child: MaterialApp(theme: AppTheme.light(), home: const HistoryScreen()),
      ));
      await tester.pumpAndSettle();
    }

    bool deleteEnabled(WidgetTester tester, String label) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, label)).onPressed != null;

    testWidgets('길게 누르면 그 항목이 선택된 채 선택 모드, 탭 토글, 헤더 탭은 그날 전체, 전체 선택', (tester) async {
      await pump(tester);
      expect(find.text('선택'), findsOneWidget);
      expect(find.text('개 선택'), findsNothing);

      await tester.longPress(find.text('캔'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('전체 선택'), findsOneWidget);
      expect(deleteEnabled(tester, '1개 삭제'), isTrue);

      // 항목 탭 = 토글 (상세로 안 간다)
      await tester.tap(find.text('캔'));
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);
      expect(find.text('판별 결과'), findsNothing);
      expect(deleteEnabled(tester, '0개 삭제'), isFalse);

      // 날짜 헤더 탭 → 오늘 2건
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);

      // 전체 선택 → 3
      await tester.tap(find.text('전체 선택'));
      await tester.pumpAndSettle();
      expect(find.text('3개 선택'), findsOneWidget);
      expect(find.text('전체 해제'), findsOneWidget);

      // 취소 → 선택 모드 해제
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('선택'), findsOneWidget);
      expect(find.text('3개 선택'), findsNothing);
    });

    testWidgets('[선택] 버튼으로 들어가 삭제: 확인 시트 → 삭제 → 스낵바, 도감도 정리', (tester) async {
      await pump(tester);
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2개 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('기록 2개를 삭제할까요?'), findsOneWidget);
      expect(find.text('삭제한 기록은 복구할 수 없어요. 이 기록으로만 등록된 도감 친구도 함께 사라져요.'), findsOneWidget);
      // 취소하면 아무 일도 없다
      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();
      expect(history.items.length, 3);
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();
      expect(find.text('기록 2개를 삭제했어요'), findsOneWidget);
      expect(history.items.single.itemName, '택배 상자');
      expect(collection.collectedIds, {'box'});
      // 삭제 뒤 선택 모드 해제
      expect(find.text('선택'), findsOneWidget);
    });

    testWidgets('뒤로가기는 선택 모드만 해제한다', (tester) async {
      await pump(tester);
      await tester.longPress(find.text('캔'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);
      expect(find.text('선택'), findsOneWidget);
      expect(find.byType(HistoryScreen), findsOneWidget);
    });
  });
}
