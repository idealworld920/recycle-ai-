import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../schedule/pickup_schedule.dart';
import 'household_model.dart';

class HouseholdException implements Exception {
  const HouseholdException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// households/{id}, households/{id}/members, households/{id}/checkins, invites/{code}
class HouseholdRepository {
  HouseholdRepository({this.firestore});

  /// 테스트에서 주입. null 이면 기본 인스턴스.
  final FirebaseFirestore? firestore;

  /// Firebase 없이 생성될 수 있도록(테스트) 실제 사용 시점에 인스턴스를 잡는다.
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _households => _db.collection('households');
  CollectionReference<Map<String, dynamic>> get _invites => _db.collection('invites');

  static String _newCode(Random rnd) => (100000 + rnd.nextInt(900000)).toString();

  /// 집 만들기. 6자리 코드는 invites/{code} 가 비어 있을 때까지 다시 뽑는다.
  Future<Household> create({required String uid, required String nickname, String name = '우리 집'}) async {
    final rnd = Random.secure();
    String code = _newCode(rnd);
    for (var i = 0; i < 5; i++) {
      if (!(await _invites.doc(code).get()).exists) break;
      code = _newCode(rnd);
    }
    final doc = _households.doc();
    final batch = _db.batch();
    batch.set(doc, {
      'code': code,
      'ownerUid': uid,
      'name': name,
      'memberUids': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(doc.collection('members').doc(uid), {'nickname': nickname, 'joinedAt': FieldValue.serverTimestamp()});
    batch.set(_invites.doc(code), {'householdId': doc.id, 'createdAt': FieldValue.serverTimestamp()});
    batch.set(_db.collection('users').doc(uid), {'householdId': doc.id}, SetOptions(merge: true));
    await batch.commit();
    return Household(id: doc.id, code: code, ownerUid: uid, name: name, memberUids: [uid]);
  }

  /// 코드로 참여.
  Future<String> join({required String code, required String uid, required String nickname}) async {
    final invite = await _invites.doc(code.trim()).get();
    final householdId = invite.data()?['householdId'] as String?;
    if (householdId == null) throw const HouseholdException('초대 코드를 찾을 수 없어요. 6자리를 다시 확인해 주세요.');
    final doc = _households.doc(householdId);
    try {
      // 규칙: memberUids 에 본인만 추가하는 변경 + 유효한 초대 코드.
      await doc.update({
        'memberUids': FieldValue.arrayUnion([uid]),
      });
      await doc.collection('members').doc(uid).set({
        'nickname': nickname,
        'joinedAt': FieldValue.serverTimestamp(),
        'code': code.trim(),
      });
      await _db.collection('users').doc(uid).set({'householdId': householdId}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const HouseholdException('참여할 수 없어요. 코드가 만료됐거나 집이 삭제됐어요.');
      rethrow;
    }
    return householdId;
  }

  Future<void> leave({required String householdId, required String uid}) async {
    final doc = _households.doc(householdId);
    await doc.collection('members').doc(uid).delete();
    await doc.update({'memberUids': FieldValue.arrayRemove([uid])});
    await _db.collection('users').doc(uid).set({'householdId': FieldValue.delete()}, SetOptions(merge: true));
  }

  Future<String?> householdIdOf(String uid) async =>
      (await _db.collection('users').doc(uid).get()).data()?['householdId'] as String?;

  Stream<Household?> watch(String householdId) => _households.doc(householdId).snapshots().map((s) {
        final d = s.data();
        return d == null ? null : Household.fromJson(s.id, d);
      });

  Stream<List<HouseholdMember>> watchMembers(String householdId) => _households
      .doc(householdId)
      .collection('members')
      .snapshots()
      .map((s) => s.docs.map((d) => HouseholdMember(uid: d.id, nickname: (d.data()['nickname'] ?? '') as String)).toList());

  Future<void> setSchedule(String householdId, PickupSchedule schedule) => _households.doc(householdId).update({
        'schedule': schedule.toJson(),
        'scheduleUpdatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> checkIn(String householdId, String dateKey, WasteType type, HouseholdMember me) =>
      _households.doc(householdId).collection('checkins').doc(dateKey).set({
        'types': {
          type.key: {'uid': me.uid, 'nickname': me.nickname, 'at': FieldValue.serverTimestamp()},
        },
      }, SetOptions(merge: true));

  Stream<Map<WasteType, MemberCheckin>> watchCheckins(String householdId, String dateKey) =>
      _households.doc(householdId).collection('checkins').doc(dateKey).snapshots().map((s) {
        final types = (s.data()?['types'] as Map?) ?? const {};
        final out = <WasteType, MemberCheckin>{};
        for (final e in types.entries) {
          final t = WasteType.fromKey(e.key.toString());
          final v = e.value;
          if (t == null || v is! Map) continue;
          final at = v['at'];
          out[t] = MemberCheckin(
            uid: (v['uid'] ?? '').toString(),
            nickname: (v['nickname'] ?? '').toString(),
            at: at is Timestamp ? at.toDate() : DateTime.now(),
          );
        }
        return out;
      });
}
