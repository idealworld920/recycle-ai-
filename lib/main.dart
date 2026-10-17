import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'app_services.dart';
import 'core/firebase_session.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/auth_store.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_store.dart';
import 'features/household/household_repository.dart';
import 'features/household/household_store.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/premium/free_limits.dart';
import 'features/premium/premium_store.dart';
import 'features/premium/purchases_service.dart';
import 'features/places/region.dart';
import 'features/places/region_store.dart';
import 'features/schedule/notification_service.dart';
import 'features/schedule/schedule_store.dart';
import 'features/schedule/widget_service.dart';
import 'features/stats/collection_store.dart';
import 'features/tips/tips_repository.dart';
import 'screens/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/settings_store.dart';

/// `--dart-define=DEMO=true` 로 빌드하면 스토어 스크린샷용 샘플 기록을 넣는다.
const bool kDemoMode = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 13+ 에서 저장소 권한 없이 시스템 포토 피커를 쓴다.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final picker = ImagePickerPlatform.instance;
    if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;
  }
  final settings = await SettingsStore.load();
  final history = await HistoryStore.load();
  final tips = await TipsRepository.load();
  final firebase = await FirebaseSession.start();
  final schedule = await ScheduleStore.load();
  await NotificationService.instance.init();
  await WidgetService.init();
  final collection = await CollectionStore.load(tips);
  final region = await RegionStore.load(await RegionRepository.load());
  final auth = await AuthStore.load(firebase.ready ? FirebaseAuthService() : OfflineAuthService(), demoLinked: kDemoMode);
  final premium = PremiumStore(PurchasesService.instance);
  final household = HouseholdStore(HouseholdRepository());
  final freeLimits = FreeLimits(await SharedPreferences.getInstance());
  schedule.attachHousehold(household);
  // 로그인되면 Firestore 와 맞춘다. 실패해도 앱은 뜬다.
  String? attachedUid;
  void attachAll() {
    if (!firebase.ready || firebase.uid == attachedUid) return;
    attachedUid = firebase.uid;
    schedule.attachUser(firebase.uid);
    history.attachUser(firebase.uid);
    collection.attachUser(firebase.uid);
    premium.attachUser(firebase.uid);
    household.attachUser(firebase.uid);
  }

  attachAll();
  firebase.addListener(attachAll);
  if (kDemoMode && history.items.isEmpty) {
    await history.seedDemo();
    await schedule.seedDemo();
    await settings.setOnboarded(true);
    await region.select(region.repository.byId('서울_마포구'));
  }
  runApp(RecycleApp(settings: settings, history: history, tips: tips, firebase: firebase, schedule: schedule, collection: collection, region: region, auth: auth, premium: premium, household: household, freeLimits: freeLimits));
}

class RecycleApp extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return AppServices(
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
      child: MaterialApp(
        title: 'ReSAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => settings.onboarded
              ? const HomeShell()
              : OnboardingScreen(onDone: () => settings.setOnboarded(true)),
        ),
      ),
    );
  }
}
