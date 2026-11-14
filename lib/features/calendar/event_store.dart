import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../household/household_store.dart';
import '../schedule/notification_service.dart';
import 'calendar_event.dart';

/// 사용자 일정 저장소.
///
/// 기기(prefs)에 항상 복사본을 두고, 로그인되면 users/{uid}/events 와, 집에 속하면 households/{id}/events 와 맞춘다.
/// 집에 속한 동안은 집 일정이 보인다(개인 일정은 보관만). 알림은 각자 폰에서 전날 20:00.
class EventStore extends ChangeNotifier {
  EventStore(this._prefs, {this.firestore, this.specialDays = const []}) {
    _local = _readLocal();
  }

  static const prefKey = 'calendar_events_v1';

  final SharedPreferences _prefs;
  final FirebaseFirestore? firestore;
  final List<SpecialDay> specialDays;
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  List<CalendarEvent> _local = const [];
  List<CalendarEvent> _remote = const [];
  String? _uid;
  String? _displayName;
  HouseholdStore? _household;
  String? _householdId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// 지금 보이는 일정: 집에 속해 있으면 집 일정, 아니면 내 일정(기기 + 서버 합집합).
  List<CalendarEvent> get events => _householdId != null ? _remote : _mergeLocal();

  List<CalendarEvent> _mergeLocal() {
    final map = {for (final e in _local) e.id: e};
    for (final e in _remote) {
      map[e.id] = e;
    }
    final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<CalendarEvent> onDay(DateTime day) {
    final key = _key(day);
    return events.where((e) => e.dateKey == key).toList(growable: false);
  }

  List<SpecialDay> specialOn(DateTime day) {
    final key = _key(day);
    return specialDays.where((s) => s.dateKey == key).toList(growable: false);
  }

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CollectionReference<Map<String, dynamic>>? get _col {
    if (_householdId != null) return _db.collection('households').doc(_householdId).collection('events');
    if (_uid != null) return _db.collection('users').doc(_uid).collection('events');
    return null;
  }

  Future<void> attachUser(String? uid, {String? displayName}) async {
    _uid = uid;
    _displayName = displayName;
    _resubscribe();
  }

  /// 집 스토어를 따라간다: 집에 들어가면 집 일정으로, 나오면 내 일정으로.
  void attachHousehold(HouseholdStore household) {
    _household = household;
    household.addListener(_onHousehold);
    _onHousehold();
  }

  void _onHousehold() {
    final id = _household?.household?.id;
    if (id == _householdId) return;
    _householdId = id;
    _resubscribe();
  }

  void _resubscribe() {
    _sub?.cancel();
    _sub = null;
    _remote = const [];
    final col = _col;
    if (col == null) {
      notifyListeners();
      return;
    }
    try {
      _sub = col.snapshots().listen((snap) {
        _remote = snap.docs.map((d) => CalendarEvent.fromJson(d.id, d.data())).toList()..sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }, onError: (Object e) => debugPrint('일정 구독 실패: $e'));
    } catch (e) {
      debugPrint('일정 구독 실패: $e');
    }
    notifyListeners();
  }

  List<CalendarEvent> _readLocal() {
    final raw = _prefs.getStringList(prefKey) ?? const [];
    final out = <CalendarEvent>[];
    for (final s in raw) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        out.add(CalendarEvent.fromJson(j['id'] as String, j));
      } catch (_) {}
    }
    return out;
  }

  Future<void> _writeLocal() => _prefs.setStringList(prefKey, _local.map((e) => jsonEncode({'id': e.id, ...e.toJson()})).toList(growable: false));

  static String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// 일정 추가 (프리미엄 게이트는 화면에서).
  Future<CalendarEvent> add({required String title, required EventKind kind, required DateTime date, bool remind = true}) async {
    final e = CalendarEvent(
      id: newId(),
      title: title.trim(),
      kind: kind,
      date: DateTime(date.year, date.month, date.day),
      remind: remind,
      createdBy: _uid ?? '',
      createdByName: _displayName ?? '',
    );
    if (_householdId == null) {
      _local = [..._local, e];
      await _writeLocal();
    }
    notifyListeners();
    final col = _col;
    if (col != null) {
      try {
        await col.doc(e.id).set({...e.toJson(), 'createdAt': FieldValue.serverTimestamp()});
      } catch (err) {
        debugPrint('일정 업로드 실패: $err');
      }
    }
    await _syncReminder(e);
    return e;
  }

  Future<void> remove(String id) async {
    final existing = events.where((e) => e.id == id).firstOrNull;
    _local = _local.where((e) => e.id != id).toList();
    await _writeLocal();
    notifyListeners();
    try {
      await _col?.doc(id).delete();
    } catch (err) {
      debugPrint('일정 삭제 동기화 실패: $err');
    }
    if (existing != null) {
      try {
        await NotificationService.instance.cancelEvent(existing.notificationId);
      } catch (_) {}
    }
  }

  /// 알림 다시 잡기 (앱 시작 시 전체).
  Future<void> rescheduleAll() async {
    for (final e in events) {
      await _syncReminder(e);
    }
  }

  Future<void> _syncReminder(CalendarEvent e) async {
    try {
      final at = e.remind ? e.remindAt(DateTime.now()) : null;
      if (at == null) {
        await NotificationService.instance.cancelEvent(e.notificationId);
      } else {
        await NotificationService.instance.scheduleEvent(id: e.notificationId, title: '내일 ${e.kind.label}', body: '${e.title} · 잊지 마세요.', at: at);
      }
    } catch (err) {
      debugPrint('일정 알림 등록 실패: $err');
    }
  }

  /// 계정 전환: 기기 복사본만 비운다.
  Future<void> resetLocal() async {
    _local = const [];
    await _writeLocal();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _household?.removeListener(_onHousehold);
    super.dispose();
  }
}
