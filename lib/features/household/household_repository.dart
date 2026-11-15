import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../schedule/pickup_schedule.dart';
import 'household_model.dart';
import 'invite_code.dart';

class HouseholdException implements Exception {
  const HouseholdException(this.message, {this.code});
  final String message;

  /// FirebaseFunctionsException.code (not-found, unavailable …). 로컬 검증 오류면 null.
  final String? code;

  /// 함수가 아직 배포되지 않았을 때 (호출 자체가 404/UNIMPLEMENTED).
  bool get notDeployed => code == 'not-found' || code == 'unimplemented';

  @override
  String toString() => message;
}

/// 집에 들어가고 나가는 변경(참여·나가기·내보내기·방장 위임)은 Cloud Function 이 검증해서 처리한다.
/// 만들기·초대 코드 재발급·수거일·체크인은 규칙 안에서 클라이언트가 직접 쓴다.
abstract class HouseholdBackend {
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data);
}

class FunctionsBackend implements HouseholdBackend {
  // ignore: prefer_initializing_formals
  FunctionsBackend({FirebaseFunctions? functions}) : _functions = functions;
  final FirebaseFunctions? _functions;
  FirebaseFunctions get _f => _functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _f.httpsCallable(name).call<Map<Object?, Object?>>(data);
      return (r.data).cast<String, dynamic>();
    } on FirebaseFunctionsException catch (e) {
      throw HouseholdException(_message(e), code: e.code);
    }
  }

  static String _message(FirebaseFunctionsException e) => switch (e.code) {
        'not-found' => '초대 코드를 찾을 수 없어요. 6자리를 다시 확인해 주세요.',
        'deadline-exceeded' => '초대 코드가 만료됐어요. 방장에게 새 코드를 받아 주세요.',
        'resource-exhausted' => '이 집은 이미 6명이 꽉 찼어요.',
        'already-exists' => '이미 집에 속해 있어요. 다른 집에 들어가려면 먼저 나가야 해요.',
        'permission-denied' => '방장만 할 수 있어요.',
        'unauthenticated' => '구글 연결 후 다시 시도해 주세요.',
        'unavailable' => '인터넷 연결을 확인해 주세요.',
        _ => e.message?.isNotEmpty == true ? e.message! : '잠시 후 다시 시도해 주세요.',
      };
}

/// households/{id}, households/{id}/checkins/{day}
class HouseholdRepository {
  HouseholdRepository({this.firestore, HouseholdBackend? backend}) : _backend = backend ?? FunctionsBackend();

  /// 테스트에서 주입. null 이면 기본 인스턴스.
  final FirebaseFirestore? firestore;
  final HouseholdBackend _backend;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _households => _db.collection('households');

  /// 집 만들기 (프리미엄 전용 — 게이트는 화면에서). 초대 코드는 24시간짜리로 바로 발급.
  Future<Household> create({required String uid, required String nickname, String name = '우리 집'}) async {
    final now = DateTime.now();
    final me = HouseholdMember(uid: uid, nickname: nickname, color: 0, joinedAt: now);
    final code = InviteCode.generate();
    final expires = InviteCode.expiryFrom(now);
    final doc = _households.doc();
    final batch = _db.batch();
    batch.set(doc, {
      'name': name,
      'ownerUid': uid,
      'memberUids': [uid],
      'members': [me.toJson()],
      'inviteCode': code,
      'inviteCodeExpiresAt': Timestamp.fromDate(expires),
      'premiumUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('users').doc(uid), {'householdId': doc.id}, SetOptions(merge: true));
    await batch.commit();
    return Household(id: doc.id, name: name, ownerUid: uid, members: [me], inviteCode: code, inviteCodeExpiresAt: expires);
  }

  /// 방장: 새 초대 코드 (24시간).
  Future<String> regenerateInvite(String householdId) async {
    final code = InviteCode.generate();
    await _households.doc(householdId).update({
      'inviteCode': code,
      'inviteCodeExpiresAt': Timestamp.fromDate(InviteCode.expiryFrom(DateTime.now())),
    });
    return code;
  }

  /// 코드로 참여 (Cloud Function joinHousehold 가 코드·만료·정원을 검증).
  Future<String> join({required String code, required String nickname}) async {
    final normalized = InviteCode.normalize(code);
    if (!InviteCode.isValid(normalized)) throw const HouseholdException('초대 코드는 영문·숫자 6자리예요.');
    final r = await _backend.call('joinHousehold', {'code': normalized, 'nickname': nickname});
    final id = r['householdId'] as String?;
    if (id == null) throw const HouseholdException('참여하지 못했어요. 잠시 후 다시 시도해 주세요.');
    return id;
  }

  Future<void> leave() => _backend.call('leaveHousehold', const {});
  Future<void> removeMember(String uid) => _backend.call('removeHouseholdMember', {'uid': uid});
  Future<void> transferOwner(String uid) => _backend.call('transferHouseholdOwner', {'uid': uid});

  Future<String?> householdIdOf(String uid) async =>
      (await _db.collection('users').doc(uid).get()).data()?['householdId'] as String?;

  Stream<Household?> watch(String householdId) => _households.doc(householdId).snapshots().map((s) {
        final d = s.data();
        return d == null ? null : Household.fromJson(s.id, d);
      });

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
