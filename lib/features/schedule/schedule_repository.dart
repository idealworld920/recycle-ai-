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

  Future<void> checkIn(String dateKey, WasteType type) async {
    final current = loadCheckinsLocal(dateKey)..add(type);
    await _prefs.setStringList('$checkinPrefPrefix$dateKey', current.map((t) => t.key).toList());
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

  /// 오래된 로컬 체크인 키 정리 (7일 지난 것).
  Future<void> pruneCheckins(DateTime now) async {
    final cutoff = now.subtract(const Duration(days: 7));
    for (final key in _prefs.getKeys().where((k) => k.startsWith(checkinPrefPrefix))) {
      final date = DateTime.tryParse(key.substring(checkinPrefPrefix.length));
      if (date != null && date.isBefore(cutoff)) await _prefs.remove(key);
    }
  }
}
