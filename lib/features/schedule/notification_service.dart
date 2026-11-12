import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/mascot.dart';
import '../tips/tip_model.dart';
import 'app_actions.dart';
import 'pickup_schedule.dart';
import 'reminder_copy.dart';

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

  /// 문구 생성기. main() 에서 팁 데이터가 준비되면 꽂아 준다. 없으면 기본 문구.
  ReminderCopy? copy;
  String? _mascotIconPath;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final p = response.payload;
        if (p == AppActions.openCamera || p == AppActions.openReport) AppActions.instance.fire(p!);
      },
    );
    _initialized = true;

    // 알림을 눌러서 앱이 켜진 경우.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final p = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && (p == AppActions.openCamera || p == AppActions.openReport)) {
        AppActions.instance.fire(p!);
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
    // 수거일 알림 id 만 지운다 (퀴즈 알림은 따로).
    for (final type in WasteType.values) {
      for (var d = 1; d <= 7; d++) {
        await _plugin.cancel(id: PickupSchedule.notificationId(type, d));
      }
    }
    if (schedule.isEmpty) return;

    final icon = await _mascotIcon();
    final now = tz.TZDateTime.now(tz.local);
    final usedTips = <Tip>[];
    for (final type in WasteType.values) {
      for (final pickupDay in schedule.daysOf(type)) {
        final tip = copy?.pickTip(type);
        if (tip != null) usedTips.add(tip);
        final body = copy?.body(type, tip: tip) ?? ReminderCopy.lead(type);
        final when = _nextInstance(now, PickupSchedule.reminderWeekday(pickupDay), schedule.notifyHour, schedule.notifyMinute);
        await _plugin.zonedSchedule(
          id: PickupSchedule.notificationId(type, pickupDay),
          title: ReminderCopy.title(type),
          body: body,
          scheduledDate: when,
          notificationDetails: _details(body, icon),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: AppActions.openCamera,
        );
      }
    }
    if (usedTips.isNotEmpty) await copy?.markUsed(usedTips);
  }

  /// 본문이 길어서 펼쳐 보이게(BigText) 하고, 리뿅이 PNG 를 큰 아이콘으로.
  NotificationDetails _details(String body, String? iconPath) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(body),
          largeIcon: iconPath == null ? null : FilePathAndroidBitmap(iconPath),
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// 알림엔 GIF 를 못 쓰므로 정지 PNG 를 앱 폴더에 한 번 복사해 둔다.
  Future<String?> _mascotIcon() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    if (_mascotIconPath != null) return _mascotIconPath;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/mascot_happy.png');
      if (!await file.exists()) {
        final data = await rootBundle.load(Mascot.happy.png);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      return _mascotIconPath = file.path;
    } catch (e) {
      debugPrint('마스코트 아이콘 준비 실패: $e');
      return null;
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

  static const monthlyReportId = 200;

  /// 매월 1일 09:00 "지난달 리포트" 알림. 앱을 켤 때마다 다시 잡아도 같은 id 라 중복되지 않는다.
  Future<void> scheduleMonthlyReport() async {
    if (kIsWeb) return;
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, 1, 9);
    if (!when.isAfter(now)) when = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 9);
    const body = '한 달 동안 뭘 얼마나 분류했는지, 재활용률은 올랐는지 정리했어요. 눌러서 확인해 보세요.';
    await _plugin.zonedSchedule(
      id: monthlyReportId,
      title: '리뿅이: 지난달 리포트 나왔뿅!',
      body: body,
      scheduledDate: when,
      notificationDetails: _details(body, await _mascotIcon()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: AppActions.openReport,
    );
  }

  /// 에뮬레이터 확인용: 5초 뒤 한 번 울리는 테스트 알림.
  Future<void> showTest(WasteType type) async {
    await init();
    final body = copy?.body(type) ?? ReminderCopy.lead(type);
    await _plugin.zonedSchedule(
      id: 1,
      title: ReminderCopy.title(type),
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      notificationDetails: _details(body, await _mascotIcon()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: AppActions.openCamera,
    );
  }
}
