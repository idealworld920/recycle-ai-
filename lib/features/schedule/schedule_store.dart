import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stats/stats_calculator.dart';
import 'notification_service.dart';
import 'pickup_schedule.dart';
import 'schedule_repository.dart';
import 'widget_service.dart';

/// 수거일 설정 + 오늘 체크인 상태. 홈 카드와 설정 시트가 구독한다.
class ScheduleStore extends ChangeNotifier {
  ScheduleStore(this._repo) {
    _schedule = _repo.loadLocal();
    _today = PickupSchedule.dateKey(DateTime.now());
    _checkins = _repo.loadCheckinsLocal(_today);
    _checkinDates = _repo.loadCheckinDatesLocal();
  }

  final ScheduleRepository _repo;
  PickupSchedule? _schedule;
  late String _today;
  Set<WasteType> _checkins = {};
  Set<String> _checkinDates = {};
  bool _saving = false;

  PickupSchedule? get schedule => _schedule;
  bool get isConfigured => _schedule?.isConfigured ?? false;
  bool get saving => _saving;

  /// 오늘 체크한 종류.
  Set<WasteType> get checkins => _checkins;
  bool isChecked(WasteType t) => _checkins.contains(t);

  /// 체크인이 있던 날짜 키들.
  Set<String> get checkinDates => _checkinDates;

  /// 주간 스트릭 (연속 주 수 + 12주 점).
  StreakResult streak(DateTime now) =>
      StatsCalculator.weeklyStreak(checkinDates: _checkinDates, schedule: _schedule, now: now);

  static Future<ScheduleStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ScheduleStore(ScheduleRepository(prefs));
  }

  /// 로그인되면 Firestore 와 맞춘다. 원격이 있으면 원격을 우선한다.
  Future<void> attachUser(String? uid) async {
    _repo.uid = uid;
    if (uid == null) return;
    final remote = await _repo.loadRemote();
    if (remote != null) {
      _schedule = remote;
      await _repo.save(remote);
      await WidgetService.refreshNow(remote);
      await NotificationService.instance.reschedule(remote);
    } else if (_schedule != null) {
      await _repo.save(_schedule!);
    }
    _checkins = await _repo.loadCheckins(_today);
    _checkinDates = await _repo.loadCheckinDates();
    notifyListeners();
  }

  /// 설정 저장: 권한 요청 → 저장 → 알림 재등록 → 위젯 갱신.
  Future<void> save(PickupSchedule s) async {
    _saving = true;
    notifyListeners();
    try {
      await NotificationService.instance.requestPermission();
      await _repo.save(s);
      _schedule = s;
      await NotificationService.instance.reschedule(s);
      await WidgetService.refreshNow(s);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// [버렸어요] 한 탭.
  Future<void> checkIn(WasteType t) async {
    _refreshDay();
    _checkins = {..._checkins, t};
    _checkinDates = {..._checkinDates, _today};
    notifyListeners();
    await _repo.checkIn(_today, t);
  }

  /// 날짜가 바뀌었으면 체크인 상태를 다시 읽는다. 홈 카드가 그릴 때 부른다.
  void _refreshDay() {
    final key = PickupSchedule.dateKey(DateTime.now());
    if (key != _today) {
      _today = key;
      _checkins = _repo.loadCheckinsLocal(_today);
      _repo.pruneCheckins(DateTime.now());
    }
  }

  /// 홈 카드용 스냅샷.
  ({List<WasteType> today, List<UpcomingPickup> upcoming}) snapshot(DateTime now) {
    _refreshDay();
    final s = _schedule;
    if (s == null) return (today: const [], upcoming: const []);
    return (today: s.todayTypes(now), upcoming: s.upcoming(now, includeToday: false));
  }
}
