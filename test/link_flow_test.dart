import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/core/boot_report.dart';
import 'package:recycle_ai/core/firebase_session.dart';
import 'package:recycle_ai/core/theme/app_sheet.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/auth_errors.dart';
import 'package:recycle_ai/features/auth/auth_service.dart';
import 'package:recycle_ai/features/auth/auth_store.dart';
import 'package:recycle_ai/features/auth/link_flows.dart';
import 'package:recycle_ai/features/calendar/event_store.dart';
import 'package:recycle_ai/features/feedback/feedback_store.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
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

/// 결과를 미리 정해 두는 가짜 인증 서비스.
class FakeAuthService implements AuthService {
  FakeAuthService(this.linkResult, {this.switchResult = const LinkSuccess()});
  LinkOutcome linkResult;
  LinkOutcome switchResult;
  int linkCalls = 0;
  int switchCalls = 0;
  int signOutCalls = 0;

  @override
  User? get currentUser => null;
  @override
  Stream<User?> get userChanges => const Stream.empty();
  @override
  Future<LinkOutcome> linkGoogle() async {
    linkCalls++;
    return linkResult;
  }

  @override
  Future<LinkOutcome> switchToExisting(AuthCredential credential) async {
    switchCalls++;
    return switchResult;
  }

  @override
  Future<void> signOutAndStartAnonymous() async => signOutCalls++;
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> deleteAuthAccountOnly() async {}
  @override
  Future<void> mergeUserDoc(Map<String, dynamic> data) async {}
  @override
  Future<Map<String, dynamic>?> readUserDoc() async => null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late HistoryStore history;

  Future<void> pump(WidgetTester tester, FakeAuthService fake, {int records = 3}) async {
    final tips = TipsRepository.fromJsonString('{"items":[]}');
    history = await HistoryStore.load();
    for (var i = 0; i < records; i++) {
      await history.addRecord(HistoryRecord(id: 'r$i', date: DateTime.now().subtract(Duration(minutes: i)), itemName: '캔 $i', category: RecycleCategory.can));
    }
    await tester.pumpWidget(AppServices(
      settings: await SettingsStore.load(),
      history: history,
      tips: tips,
      firebase: FirebaseSession.unavailable(),
      schedule: await ScheduleStore.load(),
      collection: await CollectionStore.load(tips),
      region: await RegionStore.load(RegionRepository.fromJsonString('{"items":[]}')),
      auth: await AuthStore.load(fake),
      premium: PremiumStore(PurchasesService.instance),
      household: HouseholdStore(HouseholdRepository()),
      events: EventStore(await SharedPreferences.getInstance()),
      freeLimits: FreeLimits(await SharedPreferences.getInstance()),
      boot: BootReport(),
      feedback: FeedbackStore(await SharedPreferences.getInstance()),
      carbon: const CarbonFactors(factors: {}, pine: null),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(onPressed: () => connectGoogle(context), child: const Text('CONNECT')),
                TextButton(onPressed: () => signOutFlow(context), child: const Text('SIGNOUT')),
                TextButton(
                  onPressed: () => showAppSheet(context, builder: (ctx, _) => TextButton(onPressed: () => ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('IN-SHEET'))), child: const Text('TOAST'))),
                  child: const Text('SHEET'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> tapConnect(WidgetTester tester) async {
    await tester.tap(find.text('CONNECT'));
    await tester.pumpAndSettle();
  }

  group('Google 연결 결과 처리', () {
    testWidgets('성공 → "구글 계정이 연결됐어요"', (tester) async {
      await pump(tester, FakeAuthService(const LinkSuccess()));
      await tapConnect(tester);
      expect(find.text('구글 계정이 연결됐어요'), findsOneWidget);
    });

    testWidgets('이미 연결됨 → "이미 연결돼 있어요"', (tester) async {
      await pump(tester, FakeAuthService(const LinkAlreadyLinked()));
      await tapConnect(tester);
      expect(find.text(AuthErrors.alreadyLinked), findsOneWidget);
    });

    testWidgets('취소 → 아무것도 안 띄움', (tester) async {
      await pump(tester, FakeAuthService(const LinkCancelled()));
      await tapConnect(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('네트워크 실패 / Sign-In 설정 오류(코드 10) → 각각 스낵바', (tester) async {
      final fake = FakeAuthService(LinkFailed(FirebaseAuthException(code: 'network-request-failed')));
      await pump(tester, fake);
      await tapConnect(tester);
      expect(find.text(AuthErrors.network), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      fake.linkResult = LinkFailed(PlatformException(code: '10', message: 'DEVELOPER_ERROR'));
      await tapConnect(tester);
      expect(find.text(AuthErrors.setupError), findsOneWidget);
    });

    testWidgets('이미 가입된 계정 → 시트(기록 N개) → 로그인 → 전환 + 기기 기록 비움', (tester) async {
      final cred = GoogleAuthProvider.credential(idToken: 'x');
      final fake = FakeAuthService(LinkAlreadyInUse(cred, 'a@b.com'));
      await pump(tester, fake, records: 3);
      await tapConnect(tester);
      expect(find.text('이 Google 계정으로 가입된 기록이 이미 있어요. 그 계정으로 로그인할까요?'), findsOneWidget);
      expect(find.text('지금 기기의 기록 3개는 사라져요.'), findsOneWidget);
      // 취소: 아무 일도 없다
      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();
      expect(fake.switchCalls, 0);
      expect(history.items.length, 3);
      // 로그인
      await tapConnect(tester);
      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pumpAndSettle();
      expect(fake.switchCalls, 1);
      expect(history.items, isEmpty);
      expect(find.text('기존 계정으로 로그인했어요'), findsOneWidget);
    });
  });

  testWidgets('로그아웃: 확인 시트 → signOut → 기기 기록 비움 → 스낵바', (tester) async {
    final fake = FakeAuthService(const LinkSuccess());
    await pump(tester, fake, records: 2);
    await tester.tap(find.text('SIGNOUT'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃할까요?'), findsOneWidget);
    expect(find.text('기록은 계정에 안전하게 보관돼요. 다시 로그인하면 그대로 볼 수 있어요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(fake.signOutCalls, 1);
    expect(history.items, isEmpty);
    expect(find.text('로그아웃했어요'), findsOneWidget);
  });

  testWidgets('바텀시트 안에서 띄운 스낵바는 시트 안에 보인다', (tester) async {
    await pump(tester, FakeAuthService(const LinkSuccess()));
    await tester.tap(find.text('SHEET'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TOAST'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final snack = find.byType(SnackBar);
    expect(snack, findsOneWidget);
    expect(find.ancestor(of: snack, matching: find.byType(BottomSheet)), findsOneWidget);
  });
}
