/// 수거 종류. 알림 문구와 라벨을 함께 둔다.
enum WasteType {
  recycle('recycle', '재활용', '내일 재활용 날이에요. 오늘 모아둔 거 뭐 있어요?'),
  general('general', '일반쓰레기', '내일 일반쓰레기 버리는 날이에요. 종량제 봉투 묶어둘까요?'),
  food('food', '음식물', '내일 음식물 쓰레기 버리는 날이에요. 물기 빼서 준비해요.');

  const WasteType(this.key, this.label, this.reminderBody);

  final String key;
  final String label;
  final String reminderBody;

  static WasteType? fromKey(String? key) {
    for (final t in WasteType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// 다가오는 수거 하나.
class UpcomingPickup {
  const UpcomingPickup({required this.type, required this.date, required this.daysUntil});

  final WasteType type;
  final DateTime date;

  /// 0 이면 오늘.
  final int daysUntil;

  bool get isToday => daysUntil == 0;

  String get dDayLabel => daysUntil == 0 ? 'D-Day' : 'D-$daysUntil';
}

/// 종류별 수거 요일(1=월 … 7=일)과 알림 시각. 알림은 수거 전날 울린다.
class PickupSchedule {
  const PickupSchedule({
    this.days = const {},
    this.notifyHour = 20,
    this.notifyMinute = 0,
  });

  static const defaultNotifyHour = 20;
  static const defaultNotifyMinute = 0;

  /// WasteType → 요일 집합. 비어 있으면 그 종류는 설정 안 된 것.
  final Map<WasteType, Set<int>> days;
  final int notifyHour;
  final int notifyMinute;

  bool get isEmpty => days.values.every((s) => s.isEmpty);
  bool get isConfigured => !isEmpty;

  Set<int> daysOf(WasteType t) => days[t] ?? const {};

  String get notifyTimeLabel => '${notifyHour.toString().padLeft(2, '0')}:${notifyMinute.toString().padLeft(2, '0')}';

  PickupSchedule copyWith({Map<WasteType, Set<int>>? days, int? notifyHour, int? notifyMinute}) => PickupSchedule(
        days: days ?? this.days,
        notifyHour: notifyHour ?? this.notifyHour,
        notifyMinute: notifyMinute ?? this.notifyMinute,
      );

  PickupSchedule toggleDay(WasteType t, int weekday) {
    final next = {for (final e in days.entries) e.key: {...e.value}};
    final set = next.putIfAbsent(t, () => <int>{});
    if (!set.remove(weekday)) set.add(weekday);
    return copyWith(days: next);
  }

  /// [from] 기준 그 종류의 다음 수거일. 오늘이 수거일이면 오늘.
  /// [skipToday] 가 true 면 내일부터 찾되 D-day 는 오늘 기준으로 센다.
  UpcomingPickup? next(WasteType t, DateTime from, {bool skipToday = false}) {
    final set = daysOf(t);
    if (set.isEmpty) return null;
    final today = DateTime(from.year, from.month, from.day);
    for (var i = skipToday ? 1 : 0; i <= 7; i++) {
      final d = today.add(Duration(days: i));
      if (set.contains(d.weekday)) return UpcomingPickup(type: t, date: d, daysUntil: i);
    }
    return null;
  }

  /// 오늘 수거하는 종류.
  List<WasteType> todayTypes(DateTime from) =>
      [for (final t in WasteType.values) if (daysOf(t).contains(from.weekday)) t];

  /// 가까운 순으로 정렬한 다음 수거일. [includeToday] 가 false 면 오늘 것은 뺀다.
  List<UpcomingPickup> upcoming(DateTime from, {int limit = 3, bool includeToday = true}) {
    final list = <UpcomingPickup>[];
    for (final t in WasteType.values) {
      final n = next(t, from, skipToday: !includeToday);
      if (n != null) list.add(n);
    }
    list.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.type.index.compareTo(b.type.index);
    });
    return list.take(limit).toList(growable: false);
  }

  /// 수거일 전날 요일 (월 수거면 일요일에 알림).
  static int reminderWeekday(int pickupWeekday) => pickupWeekday == 1 ? 7 : pickupWeekday - 1;

  /// 알림 id. 종류·요일마다 하나.
  static int notificationId(WasteType t, int pickupWeekday) => 100 + t.index * 10 + pickupWeekday;

  Map<String, dynamic> toJson() => {
        'days': {for (final e in days.entries) e.key.key: (e.value.toList()..sort())},
        'notifyHour': notifyHour,
        'notifyMinute': notifyMinute,
      };

  factory PickupSchedule.fromJson(Map<String, dynamic> json) {
    final raw = (json['days'] as Map?) ?? const {};
    final days = <WasteType, Set<int>>{};
    for (final e in raw.entries) {
      final t = WasteType.fromKey(e.key.toString());
      if (t == null) continue;
      days[t] = {for (final v in (e.value as List? ?? const [])) if (v is num) v.toInt()};
    }
    return PickupSchedule(
      days: days,
      notifyHour: (json['notifyHour'] as num?)?.toInt() ?? defaultNotifyHour,
      notifyMinute: (json['notifyMinute'] as num?)?.toInt() ?? defaultNotifyMinute,
    );
  }

  static const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static String weekdayLabel(int weekday) => '${weekdayLabels[weekday - 1]}요일';
  static String weekdayShort(int weekday) => weekdayLabels[weekday - 1];

  /// 날짜 키 yyyy-MM-dd (기기 로컬 시간).
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
