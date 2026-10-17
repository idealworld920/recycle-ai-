import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../household/household_model.dart';
import '../household/household_store.dart';
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
  HouseholdStore? _household;
  String? _appliedHouseholdScheduleJson;
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
  bool isChecked(WasteType t) => _checkins.contains(t) || memberCheckins.containsKey(t);

  /// 체크인이 있던 날짜 키들.
  Set<String> get checkinDates => _checkinDates;

  /// 주간 스트릭 (연속 주 수 + 12주 점).
  StreakResult streak(DateTime now) =>
      StatsCalculator.weeklyStreak(checkinDates: _checkinDates, schedule: _schedule, now: now);

  static Future<ScheduleStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ScheduleStore(ScheduleRepository(prefs));
  }

  /// 집에 속해 있으면 집 수거일·체크인을 따른다.
  void attachHousehold(HouseholdStore household) {
    _household = household;
    household.addListener(_onHouseholdChanged);
  }

  bool get inHousehold => _household?.active ?? false;

  /// 집 멤버가 오늘 체크한 기록 (닉네임·시각). 집이 없으면 비어 있다.
  Map<WasteType, MemberCheckin> get memberCheckins => _household?.todayCheckins ?? const {};

  /// 집 수거일이 바뀌면 기기에도 반영하고 알림·위젯을 다시 잡는다.
  Future<void> _onHouseholdChanged() async {
    final h = _household;
    final remote = h?.household?.schedule;
    if (h == null || !h.active) {
      _appliedHouseholdScheduleJson = null;
      notifyListeners();
      return;
    }
    if (remote == null) {
      // 집에 수거일이 아직 없으면 내 설정을 올려서 기준으로 삼는다.
      if (_schedule != null && _appliedHouseholdScheduleJson == null) {
        _appliedHouseholdScheduleJson = _schedule!.toJson().toString();
        await h.setSchedule(_schedule!);
      }
      notifyListeners();
      return;
    }
    final json = remote.toJson().toString();
    if (json != _appliedHouseholdScheduleJson) {
      _appliedHouseholdScheduleJson = json;
      _schedule = remote;
      await _repo.save(remote);
      await NotificationService.instance.reschedule(remote);
      await WidgetService.refreshNow(remote);
    }
    notifyListeners();
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
      if (inHousehold) {
        _appliedHouseholdScheduleJson = s.toJson().toString();
        await _household!.setSchedule(s);
      }
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// 계정 전환 시 기기 설정을 비운다. 알림·위젯도 같이 정리.
  Future<void> resetLocal() async {
    await _repo.resetLocal();
    _schedule = null;
    _checkins = {};
    _checkinDates = {};
    notifyListeners();
    await NotificationService.instance.reschedule(const PickupSchedule());
    await WidgetService.refreshNow(null);
  }

  /// [버렸어요] 한 탭.
  Future<void> checkIn(WasteType t) async {
    _refreshDay();
    _checkins = {..._checkins, t};
    _checkinDates = {..._checkinDates, _today};
    notifyListeners();
    await _repo.checkIn(_today, t);
    if (inHousehold) await _household!.checkIn(t);
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

  /// 스크린샷·데모용: 수거일 설정과 최근 체크인을 넣는다 (알림·위젯은 건드리지 않음).
  Future<void> seedDemo() async {
    final s = PickupSchedule(days: {
      WasteType.recycle: {DateTime.now().weekday, (DateTime.now().weekday % 7) + 1},
      WasteType.general: {1, 4},
      WasteType.food: {2, 5},
    });
    await _repo.save(s);
    _schedule = s;
    final now = DateTime.now();
    for (var w = 1; w <= 4; w++) {
      final d = now.subtract(Duration(days: 7 * w));
      await _repo.checkIn(PickupSchedule.dateKey(d), WasteType.recycle);
    }
    _checkinDates = _repo.loadCheckinDatesLocal();
    notifyListeners();
  }

  /// 홈 카드용 스냅샷.
  ({List<WasteType> today, List<UpcomingPickup> upcoming}) snapshot(DateTime now) {
    _refreshDay();
    final s = _schedule;
    if (s == null) return (today: const [], upcoming: const []);
    return (today: s.todayTypes(now), upcoming: s.upcoming(now, includeToday: false));
  }
}
