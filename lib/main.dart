import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_services.dart';
import 'core/boot_report.dart';
import 'core/firebase_session.dart';
import 'core/splash_gate.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/auth_store.dart';
import 'features/feedback/feedback_store.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_store.dart';
import 'features/household/household_repository.dart';
import 'features/household/household_store.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/premium/free_limits.dart';
import 'features/premium/premium_store.dart';
import 'features/premium/purchases_service.dart';
import 'features/report/carbon_factors.dart';
import 'features/places/admin_region.dart';
import 'features/places/region.dart';
import 'features/places/region_store.dart';
import 'features/schedule/app_actions.dart';
import 'features/schedule/notification_service.dart';
import 'features/schedule/reminder_copy.dart';
import 'features/schedule/schedule_repository.dart';
import 'features/schedule/schedule_store.dart';
import 'features/schedule/widget_service.dart';
import 'features/stats/collection_store.dart';
import 'features/tips/tips_repository.dart';
import 'screens/home_shell.dart';
import 'services/settings_store.dart';

/// `--dart-define=DEMO=true` 로 빌드하면 스토어 스크린샷용 샘플 기록을 넣는다.
const bool kDemoMode = bool.fromEnvironment('DEMO');

/// 데모 빌드에서 온보딩(첫 실행 경로)을 캡처할 때 켠다.
const bool kDemoOnboarding = bool.fromEnvironment('DEMO_ONBOARDING');

Future<void> main() async {
  // main() 안에서 무엇이 터져도 스플래시에 멈춰 있지 않게, 최소한 오류 화면은 띄운다.
  await runZonedGuarded(_boot, (e, st) {
    // ignore: avoid_print
    print('[boot] 처리되지 않은 오류: $e\n$st');
  });
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();
  BootReport.mark('시작 (release=$kReleaseMode)');
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print('[boot] Flutter 오류: ${details.exceptionAsString()}');
  };
  final boot = BootReport(silent: kDemoMode);
  // Android 13+ 에서 저장소 권한 없이 시스템 포토 피커를 쓴다.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final picker = ImagePickerPlatform.instance;
    if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;
  }

  // 1) 기기 안의 저장소만 먼저 연다. 전부 로컬이라 빠르고, 하나가 실패해도 기본값으로 간다.
  final SharedPreferences prefs;
  final SettingsStore settings;
  final HistoryStore history;
  try {
    prefs = await SharedPreferences.getInstance();
    BootReport.mark('SharedPreferences 열림');
    settings = await SettingsStore.load();
    history = await HistoryStore.load();
  } catch (e, st) {
    // ignore: avoid_print
    print('[boot] 로컬 저장소 열기 실패: $e\n$st');
    runApp(_FatalScreen(message: '$e'));
    return;
  }
  final tips = await boot.guard('팁 데이터', TipsRepository.load, fallback: () => TipsRepository.fromJsonString('{"items":[]}'));
  final schedule = await boot.guard('수거일 설정', ScheduleStore.load, fallback: () => ScheduleStore(ScheduleRepository(prefs)));
  final collection = await boot.guard('도감', () => CollectionStore.load(tips), fallback: () => CollectionStore(prefs, tips));
  final regionRepo = await boot.guard('지역 데이터', RegionRepository.load, fallback: () => RegionRepository.fromJsonString('{"items":[]}'));
  final adminRepo = await boot.guard('행정구역 데이터', AdminRegionRepository.load, fallback: AdminRegionRepository.empty);
  final region = await boot.guard('지역 설정', () => RegionStore.load(regionRepo, admin: adminRepo), fallback: () => RegionStore(prefs, regionRepo, admin: adminRepo));
  final carbon = await boot.guard('탄소 계수', CarbonFactors.load, fallback: () => const CarbonFactors(factors: {}, pine: null));
  final freeLimits = FreeLimits(prefs);
  final feedback = FeedbackStore(prefs);
  NotificationService.instance.copy = ReminderCopy(tips, prefs);
  BootReport.mark('로컬 저장소 준비 끝');

  // 2) Firebase 는 시작만 시키고 기다리지 않는다. 준비되면 저장소들이 알아서 붙는다.
  final firebase = FirebaseSession.begin();
  final auth = await AuthStore.load(SessionAuthService(firebase), demoLinked: kDemoMode);
  // 거주 지역: 고르면 users/{uid}.region 에 올리고, 기기에 없으면 서버 값을 받아온다.
  region.onRemoteSave = (data) => auth.service.mergeUserDoc({'region': data.isEmpty ? FieldValue.delete() : data});
  final premium = PremiumStore(PurchasesService.instance, prefs: prefs);
  final household = HouseholdStore(HouseholdRepository());
  schedule.attachHousehold(household);
  String? attachedUid;
  void attachAll() {
    if (!firebase.ready || firebase.uid == attachedUid) return;
    attachedUid = firebase.uid;
    schedule.attachUser(firebase.uid);
    history.attachUser(firebase.uid);
    collection.attachUser(firebase.uid);
    premium.attachUser(firebase.uid);
    household.attachUser(firebase.uid);
    feedback.attachUser(firebase.uid);
    // 온보딩 동의가 로그인 전에 끝났으면 지금 올린다.
    if (settings.consentRemotePending) {
      auth.service.mergeUserDoc({'consent': settings.consentDoc}).then((_) => settings.markConsentSynced()).catchError((_) {});
    }
    if (!region.isSet) {
      auth.service.readUserDoc().then((doc) => region.adoptRemote((doc?['region'] as Map?)?.cast<String, dynamic>())).catchError((_) {});
    }
  }

  attachAll();
  firebase.addListener(attachAll);

  if (kDemoMode && history.items.isEmpty) {
    await history.seedDemo();
    await schedule.seedDemo();
    if (!kDemoOnboarding) await settings.setOnboarded(true);
    await region.select(region.repository.byId('서울_마포구'));
  }

  // 3) 바로 그린다. 스플래시는 Firebase 가 정리되거나 최대 3초까지만 기다린다.
  BootReport.mark('runApp');
  runApp(RecycleApp(
    settings: settings,
    history: history,
    tips: tips,
    firebase: firebase,
    schedule: schedule,
    collection: collection,
    region: region,
    auth: auth,
    premium: premium,
    household: household,
    freeLimits: freeLimits,
    boot: boot,
    feedback: feedback,
    carbon: carbon,
  ));

  // 4) 알림·위젯 같은 플랫폼 플러그인은 첫 프레임 뒤에. 실패하면 배너에만 남긴다.
  unawaited(boot.run('알림', NotificationService.instance.init, timeout: const Duration(seconds: 10)));
  unawaited(boot.run('홈 위젯', WidgetService.init, timeout: const Duration(seconds: 10)));
  // 알림 팁 문구를 바꿔 준다 (같은 팁 2주 내 반복 안 함). 실패해도 조용히.
  unawaited(schedule.refreshReminders().catchError((_) {}));
  // 매월 1일 09:00 지난달 리포트 알림.
  unawaited(NotificationService.instance.scheduleMonthlyReport().catchError((_) {}));
  WidgetsBinding.instance.addPostFrameCallback((_) => BootReport.mark('첫 프레임 그림'));
}

/// 로컬 저장소조차 못 열었을 때. 흰 스플래시에 갇히는 것보다 낫다.
class _FatalScreen extends StatelessWidget {
  const _FatalScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('앱을 시작하지 못했어요', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('앱을 완전히 닫았다가 다시 열어 주세요. 계속되면 아래 내용을 알려 주세요.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                SelectableText(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecycleApp extends StatefulWidget {
  const RecycleApp({
    super.key,
    required this.settings,
    required this.history,
    required this.tips,
    required this.firebase,
    required this.schedule,
    required this.collection,
    required this.region,
    required this.auth,
    required this.premium,
    required this.household,
    required this.freeLimits,
    required this.boot,
    required this.feedback,
    required this.carbon,
  });

  final SettingsStore settings;
  final HistoryStore history;
  final TipsRepository tips;
  final FirebaseSession firebase;
  final ScheduleStore schedule;
  final CollectionStore collection;
  final RegionStore region;
  final AuthStore auth;
  final PremiumStore premium;
  final HouseholdStore household;
  final FreeLimits freeLimits;
  final BootReport boot;
  final FeedbackStore feedback;
  final CarbonFactors carbon;

  @override
  State<RecycleApp> createState() => _RecycleAppState();
}

class _RecycleAppState extends State<RecycleApp> {
  /// 이번 실행에서 온보딩을 보여줬으면, 끝난 뒤 스플래시 없이 바로 홈으로.
  bool _showedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final firebase = widget.firebase;
    return AppServices(
      settings: settings,
      history: widget.history,
      tips: widget.tips,
      firebase: firebase,
      schedule: widget.schedule,
      collection: widget.collection,
      region: widget.region,
      auth: widget.auth,
      premium: widget.premium,
      household: widget.household,
      freeLimits: widget.freeLimits,
      boot: widget.boot,
      feedback: widget.feedback,
      carbon: widget.carbon,
      child: MaterialApp(
        title: 'ReSAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // 온보딩은 Firebase(익명 로그인)를 기다리지 않는다. 끝나면 홈 위에 카메라 화면을 바로 띄운다.
        home: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            if (!settings.onboarded) {
              _showedOnboarding = true;
              // 동의 저장(onboardingDone)은 온보딩 안에서 끝난다. 여기서는 카메라 화면만 예약.
              return OnboardingScreen(onDone: () => AppActions.instance.fire(AppActions.openCapture));
            }
            if (_showedOnboarding) return const HomeShell();
            return SplashGate(until: firebase.settled, child: const HomeShell());
          },
        ),
      ),
    );
  }
}
