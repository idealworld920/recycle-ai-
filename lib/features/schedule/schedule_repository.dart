import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pickup_schedule.dart';

/// 수거 설정과 체크인 저장.
///
/// 기기(SharedPreferences)에 항상 복사본을 두고, 로그인돼 있으면 Firestore 에도 쓴다.
/// 위젯·알림은 백그라운드에서 돌기 때문에 기기 복사본을 읽는다.
class ScheduleRepository {
  ScheduleRepository(this._prefs, {this.firestore});

  static const schedulePref = 'pickup_schedule_v1';
  static const checkinPrefPrefix = 'pickup_checkin_';
  static const checkinDatesPref = 'pickup_checkin_dates_v1';

  final SharedPreferences _prefs;
  /// 테스트에서 주입. null 이면 기본 인스턴스.
  final FirebaseFirestore? firestore;

  /// 로그인된 사용자. null 이면 기기에만 저장.
  String? uid;

  FirebaseFirestore? get _db => uid == null ? null : (firestore ?? FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>>? get _settingsDoc =>
      _db?.collection('users').doc(uid).collection('settings').doc('pickup');

  DocumentReference<Map<String, dynamic>>? _checkinDoc(String dateKey) =>
      _db?.collection('users').doc(uid).collection('checkins').doc(dateKey);

  // ---- 설정 ----

  PickupSchedule? loadLocal() {
    final raw = _prefs.getString(schedulePref);
    if (raw == null) return null;
    try {
      return PickupSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 백그라운드 isolate 에서 쓰는 정적 로더.
  static Future<PickupSchedule?> loadLocalStatic() async {
    final prefs = await SharedPreferences.getInstance();
    return ScheduleRepository(prefs).loadLocal();
  }

  Future<PickupSchedule?> loadRemote() async {
    final doc = _settingsDoc;
    if (doc == null) return null;
    try {
      final snap = await doc.get();
      final data = snap.data();
      if (data == null) return null;
      return PickupSchedule.fromJson(data);
    } catch (e) {
      debugPrint('수거 설정 불러오기 실패: $e');
      return null;
    }
  }

  Future<void> save(PickupSchedule s) async {
    await _prefs.setString(schedulePref, jsonEncode(s.toJson()));
    final doc = _settingsDoc;
    if (doc == null) return;
    try {
      await doc.set({...s.toJson(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('수거 설정 동기화 실패(오프라인이면 나중에 반영됨): $e');
    }
  }

  /// 기기 복사본 전부 삭제 (설정·체크인). 계정 전환용.
  Future<void> resetLocal() async {
    await _prefs.remove(schedulePref);
    await _prefs.remove(checkinDatesPref);
    for (final key in _prefs.getKeys().where((k) => k.startsWith(checkinPrefPrefix)).toList()) {
      await _prefs.remove(key);
    }
  }

  // ---- 체크인 ----

  Set<WasteType> loadCheckinsLocal(String dateKey) {
    final list = _prefs.getStringList('$checkinPrefPrefix$dateKey') ?? const [];
    return {for (final k in list) if (WasteType.fromKey(k) != null) WasteType.fromKey(k)!};
  }

  Future<Set<WasteType>> loadCheckins(String dateKey) async {
    final local = loadCheckinsLocal(dateKey);
    final doc = _checkinDoc(dateKey);
    if (doc == null) return local;
    try {
      final snap = await doc.get();
      final types = (snap.data()?['types'] as Map?)?.keys.map((k) => WasteType.fromKey(k.toString())).nonNulls ?? const Iterable.empty();
      return {...local, ...types};
    } catch (_) {
      return local;
    }
  }

  /// 체크인이 하나라도 있던 날짜들 (스트릭용). 기기 저장본 + Firestore 최근 [days]일.
  Set<String> loadCheckinDatesLocal() => (_prefs.getStringList(checkinDatesPref) ?? const []).toSet();

  Future<Set<String>> loadCheckinDates({int days = 90}) async {
    final local = loadCheckinDatesLocal();
    final db = _db;
    if (db == null) return local;
    try {
      final cutoff = PickupSchedule.dateKey(DateTime.now().subtract(Duration(days: days)));
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('checkins')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: cutoff)
          .get();
      final merged = {...local, ...snap.docs.map((d) => d.id)};
      await _prefs.setStringList(checkinDatesPref, merged.toList());
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> checkIn(String dateKey, WasteType type) async {
    final current = loadCheckinsLocal(dateKey)..add(type);
    await _prefs.setStringList('$checkinPrefPrefix$dateKey', current.map((t) => t.key).toList());
    await _prefs.setStringList(checkinDatesPref, ({...loadCheckinDatesLocal(), dateKey}).toList());
    final doc = _checkinDoc(dateKey);
    if (doc == null) return;
    try {
      await doc.set({
        'type': type.key,
        'checkedAt': FieldValue.serverTimestamp(),
        'types': {type.key: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('체크인 동기화 실패: $e');
    }
  }

  /// 오래된 로컬 체크인 정리. 종류별 키는 7일, 날짜 목록은 90일 유지.
  Future<void> pruneCheckins(DateTime now) async {
    final cutoff = now.subtract(const Duration(days: 7));
    for (final key in _prefs.getKeys().where((k) => k.startsWith(checkinPrefPrefix) && k != checkinDatesPref)) {
      final date = DateTime.tryParse(key.substring(checkinPrefPrefix.length));
      if (date != null && date.isBefore(cutoff)) await _prefs.remove(key);
    }
    final longCutoff = PickupSchedule.dateKey(now.subtract(const Duration(days: 90)));
    final dates = loadCheckinDatesLocal().where((d) => d.compareTo(longCutoff) >= 0).toList();
    await _prefs.setStringList(checkinDatesPref, dates);
  }
}
