import 'package:flutter/widgets.dart';

import 'features/tips/tips_repository.dart';
import 'core/firebase_session.dart';
import 'features/auth/auth_store.dart';
import 'features/history/history_store.dart';
import 'features/places/region_store.dart';
import 'features/quiz/quiz_store.dart';
import 'features/schedule/schedule_store.dart';
import 'features/stats/collection_store.dart';
import 'services/settings_store.dart';

/// 화면 어디서나 저장소에 접근할 수 있게 해 주는 InheritedWidget.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.settings,
    required this.history,
    required this.tips,
    required this.firebase,
    required this.schedule,
    required this.collection,
    required this.region,
    required this.quiz,
    required this.auth,
    required super.child,
  });

  final SettingsStore settings;
  final HistoryStore history;
  final TipsRepository tips;
  final FirebaseSession firebase;
  final ScheduleStore schedule;
  final CollectionStore collection;
  final RegionStore region;
  final QuizStore quiz;
  final AuthStore auth;

  /// 계정이 바뀔 때(기존 계정 불러오기, 로그아웃, 삭제) 기기에 남은 이전 사용자 데이터를 비운다.
  Future<void> resetLocalData() async {
    await history.resetLocal();
    await collection.resetLocal();
    await schedule.resetLocal();
  }

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(scope != null, 'AppServices가 위젯 트리에 없습니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      settings != oldWidget.settings || history != oldWidget.history || tips != oldWidget.tips || firebase != oldWidget.firebase || schedule != oldWidget.schedule || collection != oldWidget.collection || region != oldWidget.region || quiz != oldWidget.quiz || auth != oldWidget.auth;
}
