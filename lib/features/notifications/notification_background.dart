import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../schedule/pickup_schedule.dart';
import '../schedule/schedule_repository.dart';

/// 알림 액션 [버렸뿅!] 을 앱을 열지 않고 처리한다 (별도 isolate).
/// payload: `checkin:<typeKey>:<dateKey>`. 기기 체크인만 즉시 기록하고, 서버·가구 반영과 분석 이벤트는
/// 다음 앱 실행 때 [PendingCheckins.flush] 가 한다.
@pragma('vm:entry-point')
Future<void> notificationActionBackground(NotificationResponse response) async {
  if (response.actionId != NotificationActions.checkin) return;
  final parsed = NotificationActions.parseCheckin(response.payload);
  if (parsed == null) return;
  final prefs = await SharedPreferences.getInstance();
  await ScheduleRepository(prefs).checkIn(parsed.$2, parsed.$1);
  await PendingCheckins(prefs).add(parsed.$2, parsed.$1);
  try {
    await FlutterLocalNotificationsPlugin().cancel(id: response.id ?? 0);
  } catch (e) {
    debugPrint('[notif] 액션 뒤 알림 제거 실패: $e');
  }
}

class NotificationActions {
  NotificationActions._();

  static const checkin = 'checkin';
  static const checkinPrefix = 'checkin:';

  static String checkinPayload(WasteType type, String dateKey) => '$checkinPrefix${type.key}:$dateKey';

  /// (type, dateKey). 받는 payload:
  ///  - `checkin:<type>:<date>` (명시)
  ///  - `pickup_morning:<type>` → 오늘
  ///  - `pickup_eve:<type>` → 내일(수거일) 기준으로 미리 체크
  static (WasteType, String)? parseCheckin(String? payload, {DateTime? now}) {
    if (payload == null) return null;
    final today = now ?? DateTime.now();
    if (payload.startsWith(checkinPrefix)) {
      final parts = payload.substring(checkinPrefix.length).split(':');
      if (parts.length != 2) return null;
      final t = WasteType.fromKey(parts[0]);
      return t == null ? null : (t, parts[1]);
    }
    final parts = payload.split(':');
    if (parts.length != 2) return null;
    final t = WasteType.fromKey(parts[1]);
    if (t == null) return null;
    return switch (parts[0]) {
      'pickup_morning' => (t, PickupSchedule.dateKey(today)),
      'pickup_eve' => (t, PickupSchedule.dateKey(today.add(const Duration(days: 1)))),
      _ => null,
    };
  }
}

/// 백그라운드에서 처리한 체크인 목록. 앱이 켜지면 서버·가구에 반영하고 이벤트를 남긴다.
class PendingCheckins {
  PendingCheckins(this._prefs);

  static const prefKey = 'pending_notification_checkins';
  final SharedPreferences _prefs;

  List<(String, WasteType)> get all => [
        for (final s in _prefs.getStringList(prefKey) ?? const <String>[])
          if (s.split('|').length == 2 && WasteType.fromKey(s.split('|')[1]) != null) (s.split('|')[0], WasteType.fromKey(s.split('|')[1])!),
      ];

  Future<void> add(String dateKey, WasteType type) async {
    final cur = _prefs.getStringList(prefKey) ?? <String>[];
    final entry = '$dateKey|${type.key}';
    if (!cur.contains(entry)) await _prefs.setStringList(prefKey, [...cur, entry]);
  }

  Future<void> clear() => _prefs.remove(prefKey);
}
