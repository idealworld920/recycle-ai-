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
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/legal/data_deletion.dart';
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('함수 미배포 코드(not-found/unimplemented)만 폴백 대상', () {
    expect(const HouseholdException('x', code: 'not-found').notDeployed, isTrue);
    expect(const HouseholdException('x', code: 'unimplemented').notDeployed, isTrue);
    expect(const HouseholdException('x', code: 'unavailable').notDeployed, isFalse);
    expect(const HouseholdException('x').notDeployed, isFalse);
  });

  testWidgets('데이터 삭제: 로딩 시트 → 기기 초기화(기록·온보딩 플래그) → 스낵바', (tester) async {
    final tips = TipsRepository.fromJsonString('{"items":[]}');
    final settings = await SettingsStore.load();
    await settings.setOnboarded(true);
    final history = await HistoryStore.load();
    await history.addRecord(HistoryRecord(id: 'a', date: DateTime.now(), itemName: '캔', category: RecycleCategory.can));
    await tester.pumpWidget(AppServices(
      settings: settings,
      history: history,
      tips: tips,
      firebase: FirebaseSession.unavailable(),
      schedule: await ScheduleStore.load(),
      collection: await CollectionStore.load(tips),
      region: await RegionStore.load(RegionRepository.fromJsonString('{"items":[]}')),
      auth: await AuthStore.load(OfflineAuthService()),
      premium: PremiumStore(PurchasesService.instance),
      household: HouseholdStore(HouseholdRepository()),
      events: EventStore(await SharedPreferences.getInstance()),
      freeLimits: FreeLimits(await SharedPreferences.getInstance()),
      boot: BootReport(),
      feedback: FeedbackStore(await SharedPreferences.getInstance()),
      carbon: const CarbonFactors(factors: {}, pine: null),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => runDataDeletion(context), child: const Text('DEL')))),
      ),
    ));
    await tester.tap(find.text('DEL'));
    await tester.pump();
    expect(find.text('삭제하고 있어요…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('데이터를 모두 삭제했어요.'), findsOneWidget);
    expect(history.items, isEmpty);
    expect(settings.onboarded, isFalse);
  });
}
