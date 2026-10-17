import 'package:flutter/widgets.dart';

import 'features/tips/tips_repository.dart';
import 'services/history_store.dart';
import 'services/settings_store.dart';

/// 화면 어디서나 저장소에 접근할 수 있게 해 주는 InheritedWidget.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.settings,
    required this.history,
    required this.tips,
    required super.child,
  });

  final SettingsStore settings;
  final HistoryStore history;
  final TipsRepository tips;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(scope != null, 'AppServices가 위젯 트리에 없습니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      settings != oldWidget.settings || history != oldWidget.history || tips != oldWidget.tips;
}
