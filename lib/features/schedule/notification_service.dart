import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../calendar/calendar_event.dart';
import '../notifications/notification_background.dart';
import '../notifications/notification_lines.dart';
import '../notifications/notification_planner.dart';
import '../notifications/notification_prefs.dart';
import 'app_actions.dart';
import 'pickup_schedule.dart';
import 'reminder_copy.dart';

/// 알림 채널 4종. 수거일 / 리포트 / 가족(FCM 포함) / 계정(체험 종료).
class NotificationChannels {
  NotificationChannels._();

  static const pickup = AndroidNotificationChannel('pickup_reminders', '수거일 알림', description: '수거일 전날 저녁·당일 아침에 알려드려요', importance: Importance.high);
  static const report = AndroidNotificationChannel('reports', '리포트·소식', description: '주간·월간 리포트와 오랜만 인사', importance: Importance.defaultImportance);
  static const family = AndroidNotificationChannel('family', '가족 공유', description: '가족이 버렸을 때, 아직 아무도 안 버렸을 때', importance: Importance.high);
  static const account = AndroidNotificationChannel('account', '계정·구독', description: '프리미엄 체험 종료 안내', importance: Importance.defaultImportance);

  static const all = [pickup, report, family, account];

  static AndroidNotificationChannel of(String key) => switch (key) {
        'report' => report,
        'family' => family,
        'account' => account,
        _ => pickup,
      };
}

/// 로컬 알림 전체를 계산할 때 필요한 입력. [NotificationService.planAll] 이 쓴다.
class NotificationPlanInput {
  const NotificationPlanInput({
    required this.schedule,
    required this.prefs,
    required this.now,
    this.weeklyClassified = 0,
    this.weeklyRecyclePercent,
    this.specialDays = const [],
    this.regionCode,
    this.regionSido,
    this.lastOpenedAt,
    this.comebackSent = false,
    this.trialStartedAt,
  });

  final PickupSchedule? schedule;
  final NotificationPrefs prefs;
  final DateTime now;
  final int weeklyClassified;
  final int? weeklyRecyclePercent;
  final List<SpecialDay> specialDays;
  final String? regionCode;
  final String? regionSido;
  final DateTime? lastOpenedAt;
  final bool comebackSent;

  /// 체험 중이면 시작 시각 (체험 종료 알림 재예약용).
  final DateTime? trialStartedAt;
}

/// 로컬 알림. 전날 저녁·당일 아침(액션 [버렸뿅!])·주간 리포트·특별 수거일·오랜만 인사·체험 종료.
/// 요일 반복 알림은 재부팅 뒤에도 플러그인의 ScheduledNotificationBootReceiver 가 다시 등록해 준다.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // 예전 코드 호환.
  static const channelId = 'pickup_reminders';
  static const channelName = '수거일 알림';
  static const channelDescription = '수거일 전날 저녁에 알려드려요';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 문구 생성기(팁 한 줄). main() 에서 팁 데이터가 준비되면 꽂아 준다.
  ReminderCopy? copy;
  String? _mascotIconPath;

  /// 알림 탭·액션을 처리할 때 호출 (앱 쪽에서 등록). payload 를 넘긴다.
  void Function(String payload)? onPayload;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) => _handleResponse(response, foreground: true),
      onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
    );
    _initialized = true;
    try {
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (a != null) {
        for (final ch in NotificationChannels.all) {
          await a.createNotificationChannel(ch);
        }
      }
    } catch (e) {
      debugPrint('[notif] 채널 생성 실패: $e');
    }

    // 알림을 눌러서 앱이 켜진 경우.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final r = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && r != null) _handleResponse(r, foreground: false);
    } catch (_) {}
  }

  /// 탭(또는 포그라운드에서 눌린 액션). payload 로 종류를 구분한다.
  void _handleResponse(NotificationResponse response, {required bool foreground}) {
    final p = response.payload;
    if (p == null) return;
    if (response.actionId == NotificationActions.checkin) {
      // 포그라운드에서 액션을 누른 경우도 백그라운드 핸들러와 같은 길로 (기기 기록 + 다음 flush).
      notificationActionBackground(response);
      onPayload?.call(NotificationPayloads.actionCheckin);
      return;
    }
    final type = NotificationPayloads.typeOf(p);
    if (type != null) Analytics.log('notification_tap', {'type': type});
    onPayload?.call(p);
    if (p == AppActions.openPremium) Analytics.log('trial_reminder_tap', {'cold_start': !foreground});
    if (p == AppActions.openCamera) Analytics.log('schedule_reminder_tap');
    final action = NotificationPayloads.appAction(p);
    if (action != null) AppActions.instance.fire(action);
  }

  /// 시스템 알림 권한이 켜져 있는가 (설정 화면 배너용).
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      await init();
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (a != null) return await a.areNotificationsEnabled() ?? false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Android 13+ POST_NOTIFICATIONS. 수거일 설정을 처음 저장할 때만 부른다 (거부해도 반복 요청 없음).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      bool? granted;
      if (android != null) {
        granted = await android.requestNotificationsPermission();
      } else {
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
      if (granted != null) {
        Analytics.log('notification_permission', {'granted': granted});
        return granted;
      }
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // 전체 예약 재계산: 앱 실행·설정 변경 때. (재부팅은 플러그인 리시버가 복구)
  // ---------------------------------------------------------------------------

  Future<void> planAll(NotificationPlanInput input) async {
    if (kIsWeb) return;
    await init();
    final lines = NotificationLines.current;
    final prefs = input.prefs;
    final icon = await _mascotIcon();

    // 1) 전날 저녁 + 당일 아침 (요일 반복)
    for (final type in WasteType.values) {
      for (var d = 1; d <= 7; d++) {
        await _plugin.cancel(id: PickupSchedule.notificationId(type, d));
        await _plugin.cancel(id: NotificationPlanner.morningId(type, d));
      }
    }
    final schedule = input.schedule;
    if (schedule != null && !schedule.isEmpty) {
      var eveScheduled = false, morningScheduled = false;
      for (final type in WasteType.values) {
        for (final pickupDay in schedule.daysOf(type)) {
          final items = NotificationPlanner.itemsLabel(schedule, pickupDay);
          if (prefs.isOn(NotificationType.pickupEve)) {
            final body = lines.body('pickupEve', vars: {'품목': items});
            await _weekly(
              id: PickupSchedule.notificationId(type, pickupDay),
              title: lines.title('pickupEve'),
              body: body,
              at: NotificationPlanner.eveTime(input.now, pickupDay, schedule, prefs.quiet),
              channel: NotificationChannels.pickup,
              icon: icon,
              payload: NotificationPayloads.withType(NotificationPayloads.pickupEve, type),
              actions: [_checkinAction()],
            );
            eveScheduled = true;
          }
          if (prefs.isOn(NotificationType.pickupMorning)) {
            final body = lines.body('pickupMorning', vars: {'품목': items});
            await _weekly(
              id: NotificationPlanner.morningId(type, pickupDay),
              title: lines.title('pickupMorning'),
              body: body,
              at: NotificationPlanner.morningTime(input.now, pickupDay, prefs),
              channel: NotificationChannels.pickup,
              icon: icon,
              payload: NotificationPayloads.withType(NotificationPayloads.pickupMorning, type),
              actions: [_checkinAction()],
            );
            morningScheduled = true;
          }
        }
      }
      if (eveScheduled) Analytics.log('notification_scheduled', {'type': NotificationType.pickupEve.key});
      if (morningScheduled) Analytics.log('notification_scheduled', {'type': NotificationType.pickupMorning.key});
    }

    // 2) 주간 리포트: 일요일 20:00, 이번 주 분류 0개면 안 잡는다 (앱을 켤 때마다 다시 계산).
    await _plugin.cancel(id: NotificationPlanner.weeklyReportId);
    if (prefs.isOn(NotificationType.weeklyReport) && input.weeklyClassified > 0) {
      final body = lines.body('weeklyReport', vars: {'N': '${input.weeklyClassified}', 'M': '${input.weeklyRecyclePercent ?? 0}'});
      await _once(
        id: NotificationPlanner.weeklyReportId,
        title: lines.title('weeklyReport'),
        body: body,
        at: NotificationPlanner.weeklyReportTime(input.now, prefs.quiet),
        channel: NotificationChannels.report,
        icon: icon,
        payload: NotificationPayloads.weeklyReport,
      );
      Analytics.log('notification_scheduled', {'type': NotificationType.weeklyReport.key});
    }

    // 3) 특별 수거일: 출처 있는 항목만(SpecialDay.fromJson 이 거른다), 지역 설정돼 있고 지역이 맞는 것만. 전날 20:00.
    for (var i = 0; i < NotificationPlanner.specialDayMax; i++) {
      await _plugin.cancel(id: NotificationPlanner.specialDayBaseId + i);
    }
    if (prefs.isOn(NotificationType.specialDay) && input.regionCode != null) {
      var i = 0;
      for (final day in input.specialDays) {
        if (!day.appliesTo(regionCode: input.regionCode, sido: input.regionSido)) continue;
        final at = NotificationPlanner.specialDayTime(input.now, day, prefs.quiet);
        if (at == null || i >= NotificationPlanner.specialDayMax) continue;
        final body = lines.body('specialDay', vars: {
          '날짜': NotificationPlanner.monthDay(day.date),
          '사유': day.title,
          '품목': NotificationPlanner.itemsLabel(schedule, day.date.weekday),
        });
        await _once(
          id: NotificationPlanner.specialDayBaseId + i,
          title: lines.title('specialDay'),
          body: body,
          at: at,
          channel: NotificationChannels.pickup,
          icon: icon,
          payload: NotificationPayloads.specialDay,
        );
        i++;
      }
      if (i > 0) Analytics.log('notification_scheduled', {'type': NotificationType.specialDay.key, 'count': i});
    }

    // 4) 오랜만 인사: 마지막 실행 +72h, 평생 1회. 앱을 켤 때마다 다시 잡히므로 72h 안 켜면 울리지 않는다.
    await _plugin.cancel(id: NotificationPlanner.comebackId);
    if (prefs.isOn(NotificationType.comeback) && !input.comebackSent && input.lastOpenedAt != null) {
      await _once(
        id: NotificationPlanner.comebackId,
        title: lines.title('comeback'),
        body: lines.body('comeback'),
        at: NotificationPlanner.comebackTime(input.lastOpenedAt!, prefs.quiet),
        channel: NotificationChannels.report,
        icon: icon,
        payload: NotificationPayloads.comeback,
      );
      Analytics.log('notification_scheduled', {'type': NotificationType.comeback.key});
    }

    // 5) 체험 종료: 토글 꺼져 있으면 취소, 체험 중이면 (다시) 예약.
    if (!prefs.isOn(NotificationType.trialEnd)) {
      await cancelTrialReminders();
    } else if (input.trialStartedAt != null) {
      await scheduleTrialReminders(startedAt: input.trialStartedAt!, quiet: prefs.quiet);
    }
  }

  /// [버렸뿅!] 액션. 어떤 품목·날짜인지는 알림 payload(`pickup_morning:<type>`)에서 백그라운드 핸들러가 읽는다.
  AndroidNotificationAction _checkinAction() => AndroidNotificationAction(
        NotificationActions.checkin,
        NotificationLines.checkinAction,
        showsUserInterface: false,
        cancelNotification: true,
      );

  Future<void> _weekly({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required AndroidNotificationChannel channel,
    required String? icon,
    required String payload,
    List<AndroidNotificationAction> actions = const [],
  }) =>
      _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details(body, icon, channel: channel, actions: actions),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );

  Future<void> _once({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required AndroidNotificationChannel channel,
    required String? icon,
    required String payload,
  }) async {
    final when = tz.TZDateTime.from(at, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _details(body, icon, channel: channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// main 이 꽂아 주는 전체 재계산 (설정·기록·지역까지 모아서 [planAll]). 없으면 기본 설정으로 수거일만.
  Future<void> Function()? replan;

  /// 수거일이 바뀌었을 때. [replan] 이 있으면 전체를 다시 잡는다.
  Future<void> reschedule(PickupSchedule schedule) async {
    if (replan != null) return replan!();
    await planAll(NotificationPlanInput(schedule: schedule, prefs: const NotificationPrefs(), now: DateTime.now()));
  }

  /// 본문이 길어서 펼쳐 보이게(BigText) 하고, 리뿅이 PNG 를 큰 아이콘으로.
  NotificationDetails _details(String body, String? iconPath, {AndroidNotificationChannel channel = NotificationChannels.pickup, List<AndroidNotificationAction> actions = const []}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: channel.importance == Importance.high ? Priority.high : Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(body),
          largeIcon: iconPath == null ? null : FilePathAndroidBitmap(iconPath),
          actions: actions,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// 알림엔 GIF 를 못 쓰므로 정지 PNG 를 앱 폴더에 한 번 복사해 둔다.
  Future<String?> _mascotIcon() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    if (_mascotIconPath != null) return _mascotIconPath;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/mascot_wink.png');
      if (!await file.exists()) {
        final data = await rootBundle.load(Mascot.wink.png);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      return _mascotIconPath = file.path;
    } catch (e) {
      debugPrint('마스코트 아이콘 준비 실패: $e');
      return null;
    }
  }

  /// 캘린더 일정 알림 (전날 20:00, 1회). id 는 CalendarEvent.notificationId (1000~).
  Future<void> scheduleEvent({required int id, required String title, required String body, required DateTime at}) async {
    if (kIsWeb) return;
    await init();
    await _once(id: id, title: title, body: body, at: at, channel: NotificationChannels.pickup, icon: await _mascotIcon(), payload: NotificationPayloads.calendarEvent);
  }

  Future<void> cancelEvent(int id) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: id);
  }

  static const monthlyReportId = 200;

  /// 매월 1일 09:00 "지난달 리포트" 알림. 앱을 켤 때마다 다시 잡아도 같은 id 라 중복되지 않는다.
  Future<void> scheduleMonthlyReport() async {
    if (kIsWeb) return;
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, 1, 9);
    if (!when.isAfter(now)) when = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 9);
    const body = '한 달 동안 뭘 얼마나 분류했는지, 재활용률은 올랐는지 정리했뿅. 눌러서 확인해보라뿅.';
    await _plugin.zonedSchedule(
      id: monthlyReportId,
      title: '지난달 리포트 나왔뿅!',
      body: body,
      scheduledDate: when,
      notificationDetails: _details(body, await _mascotIcon(), channel: NotificationChannels.report),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: AppActions.openReport,
    );
  }

  static const trialReminderIds = [300, 301];

  /// 체험 종료 알림 2개 (표준 존댓말, 리뿅이 아이콘, 계정 채널). 지난 시각은 건너뛴다.
  Future<void> scheduleTrialReminders({required DateTime startedAt, QuietHours quiet = const QuietHours()}) async {
    if (kIsWeb) return;
    await init();
    await cancelTrialReminders();
    final icon = await _mascotIcon();
    final lines = NotificationLines.current;
    final times = NotificationPlanner.trialTimes(startedAt, quiet);
    final items = [(trialReminderIds[0], 'trialEndD2', times[0]), (trialReminderIds[1], 'trialEndD1', times[1])];
    for (final (id, key, at) in items) {
      final when = tz.TZDateTime.from(at, tz.local);
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      final body = lines.body(key);
      await _plugin.zonedSchedule(
        id: id,
        title: lines.title(key),
        body: body,
        scheduledDate: when,
        notificationDetails: _details(body, icon, channel: NotificationChannels.account),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: AppActions.openPremium,
      );
    }
    Analytics.log('notification_scheduled', {'type': NotificationType.trialEnd.key});
  }

  Future<void> cancelTrialReminders() async {
    if (kIsWeb) return;
    await init();
    for (final id in trialReminderIds) {
      await _plugin.cancel(id: id);
    }
  }

  /// 에뮬레이터 확인용: 5초 뒤 한 번 울리는 테스트 알림 (당일 아침 문구 + [버렸뿅!] 액션).
  Future<void> showTest(WasteType type) async {
    await init();
    final lines = NotificationLines.current;
    final body = lines.body('pickupMorning', vars: {'품목': type.label});
    await _plugin.zonedSchedule(
      id: 1,
      title: lines.title('pickupMorning'),
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      notificationDetails: _details(body, await _mascotIcon(), actions: [_checkinAction()]),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationPayloads.withType(NotificationPayloads.pickupMorning, type),
    );
  }
}

/// 알림 payload. 탭하면 어디로 갈지 + 분석 type.
class NotificationPayloads {
  NotificationPayloads._();

  static const pickupEve = 'pickup_eve';
  static const pickupMorning = 'pickup_morning';
  static const weeklyReport = 'weekly_report';
  static const specialDay = 'special_day';
  static const comeback = 'comeback';
  static const calendarEvent = 'calendar_event';
  static const familyPush = 'family';

  /// 액션 체크인이 처리됐음을 앱에 알리는 가짜 payload.
  static const actionCheckin = 'action_checkin';

  /// `pickup_morning:recycle` 처럼 품목을 붙인다 (액션 체크인용).
  static String withType(String base, WasteType type) => '$base:${type.key}';
  static String baseOf(String payload) => payload.split(':').first;

  /// 분석 notification_tap.type
  static String? typeOf(String payload) => switch (baseOf(payload)) {
        pickupEve || pickupMorning || weeklyReport || specialDay || comeback || calendarEvent || familyPush => baseOf(payload),
        AppActions.openPremium => 'trial_end',
        AppActions.openReport => 'monthly_report',
        AppActions.openCamera => 'pickup_eve',
        _ => null,
      };

  /// 탭했을 때의 앱 동작.
  static String? appAction(String payload) => switch (baseOf(payload)) {
        pickupEve || pickupMorning || specialDay || comeback || familyPush || calendarEvent => AppActions.openHome,
        weeklyReport => AppActions.openReport,
        AppActions.openCamera || AppActions.openReport || AppActions.openPremium => payload,
        _ => null,
      };
}
