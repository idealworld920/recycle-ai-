import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_services.dart';
import 'core/analytics.dart';
import 'core/boot_report.dart';
import 'core/firebase_session.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/auth_store.dart';
import 'features/feedback/feedback_store.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_store.dart';
import 'features/calendar/calendar_event.dart';
import 'features/calendar/event_store.dart';
import 'features/household/household_repository.dart';
import 'features/mascot/ribbong_lines.dart';
import 'features/splash/splash_message_source.dart';
import 'features/splash/splash_plan.dart';
import 'features/splash/splash_screen.dart';
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
import 'core/analytics_user_props.dart';
import 'features/notifications/notification_background.dart';
import 'features/notifications/notification_lines.dart';
import 'features/notifications/notification_planner.dart';
import 'features/notifications/notification_prefs.dart';
import 'features/notifications/push_service.dart';
import 'features/premium/subscription_status.dart';

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
  final household = HouseholdStore(HouseholdRepository(), prefs: prefs);
  schedule.attachHousehold(household);
  premium.attachHousehold(household);
  final events = EventStore(prefs, specialDays: await _loadSpecialDays());
  RibbongLines.current = await RibbongLines.load();
  NotificationLines.current = await NotificationLines.load();
  final notificationPrefs = NotificationPrefsStore(prefs);
  final lastOpenedAt = settings.lastOpenedAt;
  unawaited(settings.markOpened());
  // 스플래시 공지: 지난번 fetch 값을 즉시 활성화해 읽고(기다림 짧음), 이번 fetch 는 다음 실행용으로 백그라운드.
  final splashMessage = await SplashMessageSource.readCached().timeout(const Duration(milliseconds: 400), onTimeout: () => null);
  unawaited(SplashMessageSource.prefetch());
  events.attachHousehold(household);
  // 로컬 알림 전체 재계산: 앱 실행 · 설정 변경 · 수거일 변경 · 로그인 때.
  Future<void> replanNotifications() async {
    try {
      final now = DateTime.now();
      // 오랜만 인사: 예약해 둔 시각이 지났으면(= 72h 안 켜서 울렸으면) 평생 1회 소진.
      final scheduledAt = settings.comebackScheduledAt;
      if (!settings.comebackSent && scheduledAt != null && now.isAfter(scheduledAt)) {
        await settings.markComebackSent(remote: auth.service.mergeUserDoc);
      }
      final weekStart = NotificationPlanner.weekStart(now);
      final week = history.items.where((r) => !r.date.isBefore(weekStart)).toList();
      final recyclable = week.where((r) => r.category.isRecyclable).length;
      final trial = premium.status.phase == SubscriptionPhase.trial && premium.status.expiresAt != null
          ? premium.status.expiresAt!.subtract(const Duration(days: PremiumConfig.trialDays))
          : null;
      final input = NotificationPlanInput(
        schedule: schedule.schedule,
        prefs: notificationPrefs.value,
        now: now,
        weeklyClassified: week.length,
        weeklyRecyclePercent: week.isEmpty ? null : (recyclable * 100 / week.length).round(),
        specialDays: events.specialDays,
        regionCode: region.admin?.code,
        regionSido: region.admin?.sidoShort,
        lastOpenedAt: now, // 이번 실행 기준 +72h
        comebackSent: settings.comebackSent,
        trialStartedAt: trial,
      );
      await NotificationService.instance.planAll(input);
      if (!settings.comebackSent && notificationPrefs.value.isOn(NotificationType.comeback)) {
        await settings.setComebackScheduled(NotificationPlanner.comebackTime(now, notificationPrefs.value.quiet));
      } else {
        await settings.setComebackScheduled(null);
      }
    } catch (e) {
      debugPrint('[notif] 재계산 실패: $e');
    }
  }

  notificationPrefs.onChanged = replanNotifications;
  NotificationService.instance.replan = replanNotifications;
  // 알림 액션 [버렸뿅!] 으로 백그라운드에서 쌓인 체크인 반영 (앱 실행 + 포그라운드 복귀).
  final pendingCheckins = PendingCheckins(prefs);
  NotificationService.instance.onPayload = (p) {
    if (p == NotificationPayloads.actionCheckin) unawaited(schedule.flushPendingCheckins(pendingCheckins));
  };
  unawaited(schedule.flushPendingCheckins(pendingCheckins));

  String? attachedUid;
  void attachAll() {
    if (!firebase.ready || firebase.uid == attachedUid) return;
    attachedUid = firebase.uid;
    if (settings.migratedThisLaunch) {
      settings.migratedThisLaunch = false;
      Analytics.log('onboarding_migrated'); // 1.3.1: 온보딩 없던 버전에서 온 사용자를 완료로 이관
    }
    schedule.attachUser(firebase.uid);
    history.attachUser(firebase.uid);
    collection.attachUser(firebase.uid);
    premium.attachUser(firebase.uid);
    household.attachUser(firebase.uid);
    events.attachUser(firebase.uid, displayName: auth.displayName);
    feedback.attachUser(firebase.uid);
    notificationPrefs.attachUser(firebase.uid).then((_) => replanNotifications());
    PushService.instance.attachUser(firebase.uid);
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
  // Firebase 가 준비되면 수집 on/off(ANALYTICS_DISABLED) 반영.
  firebase.addListener(() => unawaited(Analytics.configureCollection()));
  // 사용자 속성: 앱 시작 + 값이 바뀔 때마다 (이메일·구 단위 지역은 보내지 않는다).
  UserPropsSync(
    listenables: [auth, premium, region, household, collection, settings, firebase],
    read: () => UserProps.compute(
      email: auth.email,
      anonymous: auth.isAnonymous,
      premiumStatus: premium.analyticsStatus,
      regionSido: region.admin?.sidoShort,
      inHousehold: household.active,
      isOwner: household.isOwner,
      collected: collection.collected,
      installDays: settings.daysSinceInstall,
    ),
  ).start();
  // 구글 전환·로그아웃·삭제로 uid 가 바뀌면 저장소를 새 uid 에 다시 붙인다 (RevenueCat logIn 포함).
  auth.addListener(attachAll);

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
    events: events,
    lastOpenedAt: lastOpenedAt,
    splashMessage: splashMessage,
    freeLimits: freeLimits,
    boot: boot,
    feedback: feedback,
    carbon: carbon,
    notificationPrefs: notificationPrefs,
    pendingCheckins: pendingCheckins,
  ));

  // 4) 알림·위젯 같은 플랫폼 플러그인은 첫 프레임 뒤에. 실패하면 배너에만 남긴다.
  unawaited(boot.run('알림', () async {
    await NotificationService.instance.init();
    await replanNotifications();
  }, timeout: const Duration(seconds: 15)));
  unawaited(boot.run('홈 위젯', WidgetService.init, timeout: const Duration(seconds: 10)));
  // 매월 1일 09:00 지난달 리포트 알림.
  unawaited(NotificationService.instance.scheduleMonthlyReport().catchError((_) {}));
  unawaited(events.rescheduleAll().catchError((_) {}));
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
    required this.events,
    this.lastOpenedAt,
    this.splashMessage,
    required this.freeLimits,
    required this.boot,
    required this.feedback,
    required this.carbon,
    this.notificationPrefs,
    this.pendingCheckins,
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
  final EventStore events;
  final DateTime? lastOpenedAt;
  final SplashMessage? splashMessage;
  final FreeLimits freeLimits;
  final BootReport boot;
  final FeedbackStore feedback;
  final CarbonFactors carbon;
  final NotificationPrefsStore? notificationPrefs;
  final PendingCheckins? pendingCheckins;

  @override
  State<RecycleApp> createState() => _RecycleAppState();
}

class _RecycleAppState extends State<RecycleApp> with WidgetsBindingObserver {
  final _analyticsObserver = AnalyticsNavigatorObserver();
  final _navigatorKey = GlobalKey<NavigatorState>();
  /// 시작 흐름: 스플래시 → (최초 실행이면) 온보딩 → 홈. 스플래시는 Firebase 를 기다리되 전체 3초 상한.
  _Phase _phase = _Phase.splash;
  SplashPlan? _plan;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    WidgetsBinding.instance.addObserver(this);
    PushService.instance.navigatorKey = _navigatorKey;
    _reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  /// 포그라운드 복귀: 구독이 그 사이 만료·해지됐으면 바로 잠기도록 RevenueCat 을 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.premium.refresh());
      final pending = widget.pendingCheckins;
      if (pending != null) unawaited(widget.schedule.flushPendingCheckins(pending));
    }
  }

  bool? _reduceMotion;

  /// 시스템 "애니메이션 줄이기" 가 바뀌면 reduce_motion_toggle (앱엔 자체 토글이 없고 시스템 설정을 따른다).
  @override
  void didChangeAccessibilityFeatures() {
    final on = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (_reduceMotion != null && _reduceMotion != on) Analytics.log('reduce_motion_toggle', {'on': on});
    _reduceMotion = on;
  }

  /// 데이터 삭제로 온보딩 플래그가 지워지면 첫 실행처럼: 스플래시(긴 인트로) → 온보딩 1페이지.
  void _onSettings() {
    if (_phase == _Phase.home && !widget.settings.onboarded) {
      setState(() {
        _generation++;
        _plan = const SplashPlan(SplashKind.firstRun);
        _phase = _Phase.splash;
      });
    }
  }

  SplashPlan _planFor(BuildContext context) => _plan ??= SplashPlan.decide(
        onboarded: widget.settings.onboarded,
        lastOpenedAt: widget.lastOpenedAt,
        now: DateTime.now(),
        message: widget.splashMessage,
        seen: widget.settings.seenSplashIds,
        reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      );

  void _onSplashDone(SplashPlan plan) {
    if (plan.messageId != null) {
      unawaited(widget.settings.markSplashSeen(plan.messageId!, remote: widget.auth.service.mergeUserDoc));
    }
    setState(() => _phase = widget.settings.onboarded ? _Phase.home : _Phase.onboarding);
  }

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
      events: widget.events,
      freeLimits: widget.freeLimits,
      boot: widget.boot,
      feedback: widget.feedback,
      carbon: widget.carbon,
      notificationPrefs: widget.notificationPrefs,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'ReSAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorObservers: [_analyticsObserver],
        // 온보딩은 Firebase(익명 로그인)를 기다리지 않는다. 끝나면 홈 위에 카메라 화면을 바로 띄운다.
        home: Builder(
          builder: (context) => switch (_phase) {
            _Phase.splash => SplashScreen(key: ValueKey('splash$_generation'), plan: _planFor(context), ready: firebase.settled, onDone: _onSplashDone),
            _Phase.onboarding => OnboardingScreen(
                key: ValueKey('onboarding$_generation'),
                onDone: () {
                  AppActions.instance.fire(AppActions.openCapture);
                  setState(() => _phase = _Phase.home);
                },
              ),
            _Phase.home => const HomeShell(),
          },
        ),
      ),
    );
  }
}

/// assets/data/special_days.json → 출처 URL 이 있는 항목만.
Future<List<SpecialDay>> _loadSpecialDays() async {
  try {
    final raw = jsonDecode(await rootBundle.loadString('assets/data/special_days.json')) as Map<String, dynamic>;
    return ((raw['items'] as List?) ?? const []).whereType<Map>().map((m) => SpecialDay.fromJson(m.cast<String, dynamic>())).whereType<SpecialDay>().toList(growable: false);
  } catch (_) {
    return const [];
  }
}

enum _Phase { splash, onboarding, home }
