import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_actions.dart';
import 'pickup_schedule.dart';

/// 수거일 전날 알림. 요일 반복으로 잡아두면 재부팅 뒤에도 플러그인의
/// ScheduledNotificationBootReceiver 가 다시 등록해 준다.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const channelId = 'pickup_reminders';
  static const channelName = '수거일 알림';
  static const channelDescription = '수거일 전날 저녁에 알려드려요';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == AppActions.openCamera) AppActions.instance.fire(AppActions.openCamera);
      },
    );
    _initialized = true;

    // 알림을 눌러서 앱이 켜진 경우.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse?.payload == AppActions.openCamera) {
        AppActions.instance.fire(AppActions.openCamera);
      }
    } catch (_) {}
  }

  /// Android 13+ POST_NOTIFICATIONS. 수거일 설정을 저장할 때만 부른다.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
    return false;
  }

  /// 기존 알림을 모두 지우고 설정에 맞게 다시 등록한다.
  Future<void> reschedule(PickupSchedule schedule) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
    if (schedule.isEmpty) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    for (final type in WasteType.values) {
      for (final pickupDay in schedule.daysOf(type)) {
        final when = _nextInstance(now, PickupSchedule.reminderWeekday(pickupDay), schedule.notifyHour, schedule.notifyMinute);
        await _plugin.zonedSchedule(
          id: PickupSchedule.notificationId(type, pickupDay),
          title: '내일은 ${type.label} 버리는 날',
          body: type.reminderBody,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: AppActions.openCamera,
        );
      }
    }
  }

  /// [weekday](1=월…7=일) [hour]:[minute] 의 다음 시각.
  static tz.TZDateTime _nextInstance(tz.TZDateTime now, int weekday, int hour, int minute) {
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (t.weekday != weekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// 에뮬레이터 확인용: 5초 뒤 한 번 울리는 테스트 알림.
  Future<void> showTest(WasteType type) async {
    await init();
    await _plugin.zonedSchedule(
      id: 1,
      title: '내일은 ${type.label} 버리는 날',
      body: type.reminderBody,
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName, channelDescription: channelDescription, importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: AppActions.openCamera,
    );
  }
}
