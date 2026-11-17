import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';

/// 알림 종류. 설정 화면 토글 1:1. 분석 이벤트 `notification_toggle{type}` 의 type 값은 [key].
enum NotificationType {
  pickupEve('pickup_eve', '수거일 전날 저녁 알림', 'pickup'),
  pickupMorning('pickup_morning', '수거일 당일 아침 알림', 'pickup'),
  weeklyReport('weekly_report', '주간 리포트', 'report'),
  familyCheckin('family_checkin', '가족 체크인 알림', 'family'),
  familyReminder('family_reminder', '가족 미체크 리마인드', 'family'),
  specialDay('special_day', '특별 수거일 안내', 'pickup'),
  trialEnd('trial_end', '프리미엄 체험 종료 안내', 'account'),
  comeback('comeback', '오랜만 인사', 'report');

  const NotificationType(this.key, this.label, this.channel);

  final String key;
  final String label;

  /// 알림 채널: pickup | report | family | account
  final String channel;

  static NotificationType? fromKey(String? k) => NotificationType.values.where((t) => t.key == k).firstOrNull;
}

/// 방해 금지 시간. 기본 22:00~07:00. 이 안에 걸리는 알림은 끝나는 시각으로 미룬다.
class QuietHours {
  const QuietHours({this.startMinutes = 22 * 60, this.endMinutes = 7 * 60, this.enabled = true});

  final int startMinutes;
  final int endMinutes;

  /// 꺼져 있으면 어떤 알림도 미루지 않는다.
  final bool enabled;

  bool get wrapsMidnight => startMinutes > endMinutes;
  bool get isEmpty => startMinutes == endMinutes;

  QuietHours copyWith({int? startMinutes, int? endMinutes, bool? enabled}) =>
      QuietHours(startMinutes: startMinutes ?? this.startMinutes, endMinutes: endMinutes ?? this.endMinutes, enabled: enabled ?? this.enabled);

  bool contains(DateTime t) {
    if (!enabled || isEmpty) return false;
    final m = t.hour * 60 + t.minute;
    return wrapsMidnight ? (m >= startMinutes || m < endMinutes) : (m >= startMinutes && m < endMinutes);
  }

  /// [t] 가 방해 금지 안이면 그 구간이 끝나는 시각(다음 허용 시각), 아니면 그대로.
  DateTime nextAllowed(DateTime t) {
    if (!contains(t)) return t;
    final m = t.hour * 60 + t.minute;
    var day = DateTime(t.year, t.month, t.day);
    if (wrapsMidnight && m >= startMinutes) day = day.add(const Duration(days: 1));
    return DateTime(day.year, day.month, day.day, endMinutes ~/ 60, endMinutes % 60);
  }

  String get label => '${_hm(startMinutes)}~${_hm(endMinutes)}';
  static String _hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'start': startMinutes, 'end': endMinutes, 'enabled': enabled};
  factory QuietHours.fromJson(Map<String, dynamic>? j) => j == null
      ? const QuietHours()
      : QuietHours(
          startMinutes: (j['start'] as num?)?.toInt() ?? 22 * 60,
          endMinutes: (j['end'] as num?)?.toInt() ?? 7 * 60,
          enabled: j['enabled'] is bool ? j['enabled'] as bool : true,
        );
}

/// 알림 설정 값 (불변).
class NotificationPrefs {
  const NotificationPrefs({this.enabled = const {}, this.morningHour = 7, this.morningMinute = 30, this.quiet = const QuietHours()});

  /// 꺼진 것만 들어 있다 (기본은 전부 ON).
  final Map<NotificationType, bool> enabled;
  final int morningHour;
  final int morningMinute;
  final QuietHours quiet;

  bool isOn(NotificationType t) => enabled[t] ?? true;

  String get morningLabel => '${morningHour.toString().padLeft(2, '0')}:${morningMinute.toString().padLeft(2, '0')}';

  NotificationPrefs copyWith({Map<NotificationType, bool>? enabled, int? morningHour, int? morningMinute, QuietHours? quiet}) => NotificationPrefs(
        enabled: enabled ?? this.enabled,
        morningHour: morningHour ?? this.morningHour,
        morningMinute: morningMinute ?? this.morningMinute,
        quiet: quiet ?? this.quiet,
      );

  Map<String, dynamic> toJson() => {
        'enabled': {for (final e in enabled.entries) e.key.key: e.value},
        'morningHour': morningHour,
        'morningMinute': morningMinute,
        'quiet': quiet.toJson(),
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) {
    final en = <NotificationType, bool>{};
    final raw = j['enabled'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final t = NotificationType.fromKey(k.toString());
        if (t != null && v is bool) en[t] = v;
      });
    }
    return NotificationPrefs(
      enabled: en,
      morningHour: (j['morningHour'] as num?)?.toInt() ?? 7,
      morningMinute: (j['morningMinute'] as num?)?.toInt() ?? 30,
      quiet: QuietHours.fromJson((j['quiet'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

/// 알림 설정 저장소. 기기(prefs) + users/{uid}/settings/notifications. 바뀌면 [onChanged] 로 예약을 다시 잡는다.
class NotificationPrefsStore extends ChangeNotifier {
  NotificationPrefsStore(this._prefs, {FirebaseFirestore? firestore}) : _firestore = firestore { // ignore: prefer_initializing_formals
    final raw = _prefs.getString(prefKey);
    if (raw != null) {
      try {
        _value = NotificationPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  static const prefKey = 'notification_prefs_v1';

  final SharedPreferences _prefs;
  final FirebaseFirestore? _firestore;
  NotificationPrefs _value = const NotificationPrefs();
  String? _uid;

  /// 값이 바뀐 뒤 (예약 재계산용).
  Future<void> Function()? onChanged;

  NotificationPrefs get value => _value;
  bool isOn(NotificationType t) => _value.isOn(t);

  DocumentReference<Map<String, dynamic>>? get _doc =>
      _uid == null ? null : (_firestore ?? FirebaseFirestore.instance).collection('users').doc(_uid).collection('settings').doc('notifications');

  /// 로그인되면 서버 값을 받아 합친다 (서버에 있으면 서버 우선, 없으면 기기 값을 올린다).
  Future<void> attachUser(String? uid) async {
    _uid = uid;
    final doc = _doc;
    if (doc == null) return;
    try {
      final snap = await doc.get();
      final data = snap.data();
      if (data != null && data.isNotEmpty) {
        _value = NotificationPrefs.fromJson(data);
        await _prefs.setString(prefKey, jsonEncode(_value.toJson()));
        notifyListeners();
      } else {
        await doc.set({..._value.toJson(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('알림 설정 동기화 실패: $e');
    }
  }

  Future<void> setEnabled(NotificationType t, bool on) async {
    await _save(_value.copyWith(enabled: {..._value.enabled, t: on}));
    Analytics.log('notification_toggle', {'type': t.key, 'on': on});
  }

  Future<void> setMorningTime(int hour, int minute) => _save(_value.copyWith(morningHour: hour, morningMinute: minute));

  Future<void> setQuietHours(QuietHours q) async {
    await _save(_value.copyWith(quiet: q));
    Analytics.log('quiet_hours_changed', {'start': q.startMinutes, 'end': q.endMinutes, 'on': q.enabled});
  }

  Future<void> setQuietEnabled(bool on) => setQuietHours(_value.quiet.copyWith(enabled: on));

  Future<void> _save(NotificationPrefs v) async {
    _value = v;
    await _prefs.setString(prefKey, jsonEncode(v.toJson()));
    notifyListeners();
    final doc = _doc;
    if (doc != null) {
      try {
        await doc.set({...v.toJson(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('알림 설정 저장 실패(오프라인이면 나중에 반영): $e');
      }
    }
    await onChanged?.call();
  }

  /// 계정 전환: 기기 값만 기본으로.
  Future<void> resetLocal() async {
    _value = const NotificationPrefs();
    await _prefs.remove(prefKey);
    notifyListeners();
  }
}
