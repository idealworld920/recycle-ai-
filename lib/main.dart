import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/firebase_session.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_store.dart';
import 'features/tips/tips_repository.dart';
import 'screens/home_shell.dart';
import 'services/settings_store.dart';

/// `--dart-define=DEMO=true` 로 빌드하면 스토어 스크린샷용 샘플 기록을 넣는다.
const bool kDemoMode = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final history = await HistoryStore.load();
  final tips = await TipsRepository.load();
  final firebase = await FirebaseSession.start();
  if (kDemoMode && history.items.isEmpty) {
    await history.seedDemo();
  }
  runApp(RecycleApp(settings: settings, history: history, tips: tips, firebase: firebase));
}

class RecycleApp extends StatelessWidget {
  const RecycleApp({super.key, required this.settings, required this.history, required this.tips, required this.firebase});

  final SettingsStore settings;
  final HistoryStore history;
  final TipsRepository tips;
  final FirebaseSession firebase;

  @override
  Widget build(BuildContext context) {
    return AppServices(
      settings: settings,
      history: history,
      tips: tips,
      firebase: firebase,
      child: MaterialApp(
        title: 'ReSAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
