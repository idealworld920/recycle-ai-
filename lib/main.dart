import 'package:flutter/material.dart';

import 'app_services.dart';
import 'screens/home_shell.dart';
import 'services/history_store.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

/// `--dart-define=DEMO=true` 로 빌드하면 스토어 스크린샷용 샘플 기록을 넣는다.
const bool kDemoMode = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final history = await HistoryStore.load();
  if (kDemoMode && history.items.isEmpty) {
    await history.seedDemo();
  }
  runApp(RecycleApp(settings: settings, history: history));
}

class RecycleApp extends StatelessWidget {
  const RecycleApp({super.key, required this.settings, required this.history});

  final SettingsStore settings;
  final HistoryStore history;

  @override
  Widget build(BuildContext context) {
    return AppServices(
      settings: settings,
      history: history,
      child: MaterialApp(
        title: 'ReSAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeShell(),
      ),
    );
  }
}
