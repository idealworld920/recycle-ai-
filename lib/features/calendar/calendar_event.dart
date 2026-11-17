import 'package:cloud_firestore/cloud_firestore.dart';

import '../schedule/pickup_schedule.dart';

/// 사용자 일정 종류.
enum EventKind {
  bulky('bulky', '대형폐기물 신고'),
  battery('battery', '폐건전지·폐형광등'),
  other('other', '기타');

  const EventKind(this.key, this.label);
  final String key;
  final String label;

  static EventKind fromKey(String? k) => EventKind.values.where((e) => e.key == k).firstOrNull ?? EventKind.other;
}

/// 캘린더 사용자 일정 (프리미엄). 집 공유 중이면 households/{id}/events, 아니면 users/{uid}/events.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.kind,
    required this.date,
    this.remind = true,
    this.createdBy = '',
    this.createdByName = '',
  });

  final String id;
  final String title;
  final EventKind kind;

  /// 날짜(자정). 시각은 쓰지 않는다.
  final DateTime date;

  /// 전날 20:00 알림.
  final bool remind;
  final String createdBy;
  final String createdByName;

  static const remindHour = 20;

  String get dateKey => PickupSchedule.dateKey(date);

  /// 전날 20:00. 이미 지난 시각이면 null.
  DateTime? remindAt(DateTime now) {
    final t = DateTime(date.year, date.month, date.day - 1, remindHour);
    return t.isAfter(now) ? t : null;
  }

  /// 알림 id: 1000 + 안정적인 해시 (수거일 100~199, 리포트 200 과 겹치지 않게).
  int get notificationId => 1000 + (id.hashCode.abs() % 100000);

  CalendarEvent copyWith({String? title, EventKind? kind, DateTime? date, bool? remind}) => CalendarEvent(
        id: id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        date: date ?? this.date,
        remind: remind ?? this.remind,
        createdBy: createdBy,
        createdByName: createdByName,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'kind': kind.key,
        'date': dateKey,
        'remind': remind,
        'createdBy': createdBy,
        'createdByName': createdByName,
      };

  factory CalendarEvent.fromJson(String id, Map<String, dynamic> j) {
    final raw = j['date'];
    DateTime date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else {
      date = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }
    return CalendarEvent(
      id: id,
      title: (j['title'] ?? '') as String,
      kind: EventKind.fromKey(j['kind'] as String?),
      date: DateTime(date.year, date.month, date.day),
      remind: (j['remind'] as bool?) ?? true,
      createdBy: (j['createdBy'] ?? '') as String,
      createdByName: (j['createdByName'] ?? '') as String,
    );
  }
}

/// 전국 공통 일정 (assets/data/special_days.json). 출처 URL 이 없는 항목은 넣지 않는다.
class SpecialDay {
  const SpecialDay({required this.date, required this.title, required this.note, required this.sourceUrl, this.region});

  final DateTime date;
  final String title;
  final String note;
  final String sourceUrl;

  /// 적용 지역: null 이면 전국, 아니면 시도 짧은 이름("서울") 또는 행정구역 코드. 알림은 사용자 지역이 맞을 때만.
  final String? region;

  String get dateKey => PickupSchedule.dateKey(date);

  bool appliesTo({String? regionCode, String? sido}) => region == null || region == regionCode || region == sido;

  static SpecialDay? fromJson(Map<String, dynamic> j) {
    final d = DateTime.tryParse(j['date']?.toString() ?? '');
    final url = (j['sourceUrl'] ?? '') as String;
    if (d == null || !url.startsWith('https://')) return null;
    final region = j['region']?.toString().trim();
    return SpecialDay(
      date: DateTime(d.year, d.month, d.day),
      title: (j['title'] ?? '') as String,
      note: (j['note'] ?? '') as String,
      sourceUrl: url,
      region: region == null || region.isEmpty ? null : region,
    );
  }
}
