import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/app_services.dart';
import 'package:recycle_ai/core/boot_report.dart';
import 'package:recycle_ai/core/firebase_session.dart';
import 'package:recycle_ai/core/theme/app_theme.dart';
import 'package:recycle_ai/features/auth/auth_service.dart';
import 'package:recycle_ai/features/auth/auth_store.dart';
import 'package:recycle_ai/features/feedback/feedback_store.dart';
import 'package:recycle_ai/features/history/history_store.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/onboarding/intro_animation.dart';
import 'package:recycle_ai/features/onboarding/onboarding_screen.dart';
import 'package:recycle_ai/features/places/region.dart';
import 'package:recycle_ai/features/places/region_store.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:recycle_ai/features/report/carbon_factors.dart';
import 'package:recycle_ai/features/schedule/schedule_store.dart';
import 'package:recycle_ai/features/stats/collection_store.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsStore settings;
  var doneCount = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    doneCount = 0;
  });

  Future<void> pump(WidgetTester tester, {bool replay = false, bool reduceMotion = false}) async {
    settings = await SettingsStore.load();
    final tips = TipsRepository.fromJsonString('{"items":[]}');
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        history: await HistoryStore.load(),
        tips: tips,
        firebase: FirebaseSession.unavailable(),
        schedule: await ScheduleStore.load(),
        collection: await CollectionStore.load(tips),
        region: await RegionStore.load(RegionRepository.fromJsonString('{"items":[]}')),
        auth: await AuthStore.load(OfflineAuthService()),
        premium: PremiumStore(PurchasesService.instance),
        household: HouseholdStore(HouseholdRepository()),
        freeLimits: FreeLimits(await SharedPreferences.getInstance()),
        boot: BootReport(),
        feedback: FeedbackStore(await SharedPreferences.getInstance()),
        carbon: const CarbonFactors(factors: {}, pine: null),
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: OnboardingScreen(replay: replay, onDone: () => doneCount++),
        ),
      ),
    );
  }

  /// 인트로(2.6초) + 슬라이드(200ms)를 지나 1페이지로.
  Future<void> passIntro(WidgetTester tester) async {
    await tester.pump(OnboardingIntro.finishAt);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(OnboardingIntro), findsNothing);
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();
  }

  double bubbleOpacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.ancestor(of: find.text(OnboardingIntro.bubbleText), matching: find.byType(AnimatedOpacity))).opacity;

  bool startEnabled(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, '시작하기')).onPressed != null;

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('온보딩', () {
    testWidgets('최초 실행: 인트로 → 1 → 2 → 동의 → 시작하기', (tester) async {
      await pump(tester);
      // 0) 인트로: 1.6초 전엔 말풍선이 안 보이고, 그 뒤 페이드인
      expect(find.byType(OnboardingIntro), findsOneWidget);
      expect(bubbleOpacity(tester), 0);
      await tester.pump(OnboardingIntro.bubbleAt);
      expect(bubbleOpacity(tester), 1);
      await tester.pump(OnboardingIntro.finishAt - OnboardingIntro.bubbleAt);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(OnboardingIntro), findsNothing);

      // 1) 핵심 가치
      expect(find.text('찍으면 알려줘요'), findsOneWidget);
      expect(find.text('컵라면 용기'), findsOneWidget); // ResultCard 목업
      expect(find.text('건너뛰기'), findsOneWidget);
      await tapNext(tester);

      // 2) 루틴
      expect(find.text('수거일도 챙겨드려요'), findsOneWidget);
      expect(find.text('오늘 재활용 버리는 날!'), findsOneWidget);
      await tapNext(tester);

      // 3) 동의: 필수 2개 전엔 비활성
      expect(find.text('시작하기 전에'), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing);
      expect(startEnabled(tester), isFalse);
      await tester.tap(find.text('[필수] 이용약관 동의'));
      await tester.pump();
      expect(startEnabled(tester), isFalse);
      await tester.tap(find.text('[필수] 개인정보처리방침 동의'));
      await tester.pump();
      expect(startEnabled(tester), isTrue);

      await tester.tap(find.widgetWithText(FilledButton, '시작하기'));
      await tester.pumpAndSettle();
      expect(doneCount, 1);
      expect(settings.onboarded, isTrue);
      expect(settings.consentedRequired, isTrue);
      expect(settings.consentedMarketing, isFalse);
      // 익명 로그인 전이라 서버 기록은 보류
      expect(settings.consentRemotePending, isTrue);
      expect(settings.consentDoc['version'], '2026-11');
    });

    testWidgets('모두 동의를 누르면 선택 항목까지 켜지고 marketing=true 로 저장된다', (tester) async {
      await pump(tester);
      await passIntro(tester);
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('모두 동의'));
      await tester.pump();
      expect(startEnabled(tester), isTrue);
      await tester.tap(find.widgetWithText(FilledButton, '시작하기'));
      await tester.pumpAndSettle();
      expect(settings.consentedMarketing, isTrue);
      expect(doneCount, 1);
    });

    testWidgets('건너뛰기는 동의 페이지로 간다', (tester) async {
      await pump(tester);
      await passIntro(tester);
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      expect(find.text('시작하기 전에'), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing);
      expect(startEnabled(tester), isFalse);
      expect(settings.onboarded, isFalse);
    });

    testWidgets('동의 페이지에서 뒤로가기는 2페이지로', (tester) async {
      await pump(tester);
      await passIntro(tester);
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      expect(find.text('시작하기 전에'), findsOneWidget);
      await systemBack(tester);
      expect(find.text('수거일도 챙겨드려요'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
      expect(doneCount, 0);
    });

    testWidgets('인트로는 아무 데나 탭하면 바로 1페이지로', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(OnboardingIntro));
      await tester.pump(); // 슬라이드 시작
      await tester.pump(const Duration(milliseconds: 250)); // 200ms 슬라이드 끝
      expect(find.byType(OnboardingIntro), findsNothing);
      expect(find.text('찍으면 알려줘요'), findsOneWidget);
    });

    testWidgets('다시 보기: 동의 없이 0→1→2 보고 끝난다', (tester) async {
      await pump(tester, replay: true);
      expect(find.byType(OnboardingIntro), findsOneWidget);
      await passIntro(tester);
      expect(find.text('찍으면 알려줘요'), findsOneWidget);
      await tapNext(tester);
      expect(find.text('수거일도 챙겨드려요'), findsOneWidget);
      expect(find.text('시작하기 전에'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '홈으로'));
      await tester.pumpAndSettle();
      expect(doneCount, 1);
      expect(settings.onboarded, isFalse); // 다시 보기는 동의·완료 플래그를 건드리지 않는다
    });

    testWidgets('애니메이션 줄이기: 정지 이미지 1초 후 넘어가고 페이지 GIF 대신 PNG', (tester) async {
      await pump(tester, reduceMotion: true);
      final img = tester.widget<Image>(find.descendant(of: find.byType(OnboardingIntro), matching: find.byType(Image)));
      expect((img.image as AssetImage).assetName, endsWith('r_intro_static.png'));
      expect(bubbleOpacity(tester), 1);
      await tester.pump(OnboardingIntro.reducedHold);
      await tester.pump();
      expect(find.byType(OnboardingIntro), findsNothing);
      final pageImages = tester.widgetList<Image>(find.byType(Image)).map((i) => (i.image as AssetImage).assetName);
      expect(pageImages.any((n) => n.endsWith('r_wink_static.png')), isTrue);
      expect(pageImages.any((n) => n.endsWith('.gif')), isFalse);
    });
  });
}
