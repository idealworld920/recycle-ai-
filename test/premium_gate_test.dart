import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/core/boot_report.dart';
import 'package:recycle_ai/core/firebase_session.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/auth_service.dart';
import 'package:recycle_ai/features/auth/auth_store.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/places/region.dart';
import 'package:recycle_ai/features/places/region_store.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_gate.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:recycle_ai/features/schedule/schedule_store.dart';
import 'package:recycle_ai/features/stats/collection_store.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('결제가 안 열린 빌드에선 페이월 대신 "곧 출시" 안내를 띄우고 false 를 돌려준다', (tester) async {
    final tips = TipsRepository.fromJsonString('{"items":[]}');
    bool? result;
    await tester.pumpWidget(AppServices(
      settings: await SettingsStore.load(),
      history: await HistoryStore.load(),
      tips: tips,
      firebase: FirebaseSession.unavailable(),
      schedule: await ScheduleStore.load(),
      collection: await CollectionStore.load(tips),
      region: await RegionStore.load(RegionRepository.fromJsonString('{"items":[]}')),
      auth: await AuthStore.load(OfflineAuthService()),
      premium: PremiumStore(PurchasesService.instance), // 테스트엔 RevenueCat 키가 없다 → available=false
      household: HouseholdStore(HouseholdRepository()),
      freeLimits: FreeLimits(await SharedPreferences.getInstance()),
      boot: BootReport(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await ensurePremium(context, reason: '오늘 무료 분류를 다 썼어요'),
            child: const Text('GO'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('GO'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 무료 분류를 다 썼어요'), findsOneWidget);
    expect(find.textContaining('곧 출시'), findsOneWidget);
    expect(find.text('7일 무료로 시작'), findsNothing);
    await tester.tap(find.text('알겠어요'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
