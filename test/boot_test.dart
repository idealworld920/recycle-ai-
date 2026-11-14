import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/core/boot_banner.dart';
import 'package:recycle_ai/core/boot_report.dart';
import 'package:recycle_ai/core/firebase_session.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/auth_service.dart';
import 'package:recycle_ai/features/auth/auth_store.dart';
import 'package:recycle_ai/features/feedback/feedback_store.dart';
import 'package:recycle_ai/features/report/carbon_factors.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/calendar/event_store.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/places/region.dart';
import 'package:recycle_ai/features/places/region_store.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:recycle_ai/features/schedule/schedule_store.dart';
import 'package:recycle_ai/features/stats/collection_store.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('시작 단계 실패는 홈 배너에 이유와 함께 보이고 닫을 수 있다', (tester) async {
    final boot = BootReport();
    await boot.run('알림', () async => throw StateError('플러그인 없음'));
    final tips = TipsRepository.fromJsonString('{"items":[]}');
    final region = RegionRepository.fromJsonString('{"items":[]}');
    await tester.pumpWidget(AppServices(
      settings: await SettingsStore.load(),
      history: await HistoryStore.load(),
      tips: tips,
      firebase: FirebaseSession.unavailable('설정이 없어요.'),
      schedule: await ScheduleStore.load(),
      collection: await CollectionStore.load(tips),
      region: await RegionStore.load(region),
      auth: await AuthStore.load(OfflineAuthService()),
      premium: PremiumStore(PurchasesService.instance),
      household: HouseholdStore(HouseholdRepository()),
      events: EventStore(await SharedPreferences.getInstance()),
      freeLimits: FreeLimits(await SharedPreferences.getInstance()),
      boot: boot,
      feedback: FeedbackStore(await SharedPreferences.getInstance()),
      carbon: const CarbonFactors(factors: {}, pine: null),
      child: MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: BootBanner())),
    ));
    expect(find.text('일부 기능을 준비하지 못했어요'), findsOneWidget);
    expect(find.textContaining('알림: 플러그인 없음'), findsOneWidget);
    expect(find.textContaining('AI·동기화: 설정이 없어요.'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();
    expect(find.text('일부 기능을 준비하지 못했어요'), findsNothing);
  });

  test('guard 는 실패·타임아웃 때 기본값을 돌려주고 기록한다', () async {
    final boot = BootReport();
    final v = await boot.guard<int>('느림', () => Completer<int>().future, fallback: () => 7, timeout: const Duration(milliseconds: 50));
    expect(v, 7);
    expect(boot.issues.single.step, '느림');
    expect(boot.issues.single.message, '응답이 너무 오래 걸려요.');
  });
}
