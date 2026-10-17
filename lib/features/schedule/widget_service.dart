import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'pickup_schedule.dart';
import 'schedule_repository.dart';

/// 안드로이드 홈 위젯 데이터 갱신. 작은 위젯(2x1)과 중간 위젯(4x2).
///
/// 포그라운드에서는 설정이 바뀔 때 바로 갱신하고, WorkManager 로 매일 자정쯤 한 번 더 갱신한다.
class WidgetService {
  WidgetService._();

  static const smallProvider = 'PickupSmallWidget';
  static const mediumProvider = 'PickupMediumWidget';

  static const dailyTask = 'resai.pickup.widget.daily';
  static const refreshTask = 'resai.pickup.widget.refresh';

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 앱 시작 시 한 번. WorkManager 초기화 + 매일 자정 갱신 등록.
  static Future<void> init() async {
    if (!supported) return;
    try {
      await Workmanager().initialize(widgetCallbackDispatcher);
      final now = DateTime.now();
      final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
      await Workmanager().registerPeriodicTask(
        dailyTask,
        dailyTask,
        frequency: const Duration(hours: 24),
        initialDelay: nextMidnight.difference(now),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('WorkManager 초기화 실패: $e');
    }
  }

  /// 설정 변경 직후: 바로 갱신하고, 백그라운드 경로도 한 번 태운다.
  static Future<void> refreshNow(PickupSchedule? schedule) async {
    if (!supported) return;
    try {
      await writeWidgetData(schedule, DateTime.now());
      await Workmanager().registerOneOffTask(
        '$refreshTask.${DateTime.now().millisecondsSinceEpoch}',
        refreshTask,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('위젯 갱신 실패: $e');
    }
  }

  /// 위젯이 읽는 키에 값을 쓰고 두 위젯을 다시 그린다. 백그라운드에서도 호출된다.
  static Future<void> writeWidgetData(PickupSchedule? schedule, DateTime now) async {
    final list = schedule?.upcoming(now, limit: 3) ?? const <UpcomingPickup>[];
    final configured = schedule?.isConfigured ?? false;

    await HomeWidget.saveWidgetData<bool>('configured', configured);
    if (list.isEmpty) {
      await HomeWidget.saveWidgetData<String>('small_label', '수거일');
      await HomeWidget.saveWidgetData<String>('small_dday', '설정');
      await HomeWidget.saveWidgetData<String>('small_sub', '앱에서 수거일을 설정하세요');
      await HomeWidget.saveWidgetData<bool>('small_today', false);
    } else {
      final first = list.first;
      await HomeWidget.saveWidgetData<String>('small_label', first.type.label);
      await HomeWidget.saveWidgetData<String>('small_dday', first.dDayLabel);
      await HomeWidget.saveWidgetData<String>('small_sub', first.isToday ? '오늘 버리는 날' : PickupSchedule.weekdayLabel(first.date.weekday));
      await HomeWidget.saveWidgetData<bool>('small_today', first.isToday);
    }
    for (var i = 0; i < 3; i++) {
      final item = i < list.length ? list[i] : null;
      await HomeWidget.saveWidgetData<String>('m${i}_label', item?.type.label ?? '');
      await HomeWidget.saveWidgetData<String>('m${i}_dday', item?.dDayLabel ?? '');
      await HomeWidget.saveWidgetData<String>('m${i}_sub', item == null ? '' : PickupSchedule.weekdayShort(item.date.weekday));
      await HomeWidget.saveWidgetData<bool>('m${i}_today', item?.isToday ?? false);
    }
    await HomeWidget.saveWidgetData<String>('updated_at', PickupSchedule.dateKey(now));
    await HomeWidget.updateWidget(androidName: smallProvider);
    await HomeWidget.updateWidget(androidName: mediumProvider);
  }
}

/// WorkManager 진입점. 별도 isolate 에서 실행되므로 기기 저장본만 읽는다.
@pragma('vm:entry-point')
void widgetCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final schedule = await ScheduleRepository.loadLocalStatic();
      await WidgetService.writeWidgetData(schedule, DateTime.now());
      return true;
    } catch (e) {
      debugPrint('위젯 백그라운드 갱신 실패: $e');
      return false;
    }
  });
}
