import 'package:cloud_firestore/cloud_firestore.dart';

/// 하루 질문 횟수. users/{uid}/usage/{yyyy-MM-dd} 문서의 count 를 쓴다.
/// 날짜는 한국 시간(KST, UTC+9) 기준이라 자정에 리셋된다.
class UsageRepository {
  UsageRepository({required this.uid, FirebaseFirestore? firestore, DateTime Function()? now})
      : _db = firestore ?? FirebaseFirestore.instance,
        _now = now ?? DateTime.now;

  static const dailyLimit = 5;

  final String uid;
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  /// 오늘 날짜 키 (KST).
  static String dayKey(DateTime utcOrLocal) {
    final kst = utcOrLocal.toUtc().add(const Duration(hours: 9));
    final m = kst.month.toString().padLeft(2, '0');
    final d = kst.day.toString().padLeft(2, '0');
    return '${kst.year}-$m-$d';
  }

  DocumentReference<Map<String, dynamic>> get _todayDoc =>
      _db.collection('users').doc(uid).collection('usage').doc(dayKey(_now()));

  Future<int> todayCount() async {
    final snap = await _todayDoc.get();
    final v = snap.data()?['count'];
    return v is num ? v.toInt() : 0;
  }

  Future<int> remaining() async => (dailyLimit - await todayCount()).clamp(0, dailyLimit);

  /// 1 증가. 규칙상 1씩만 늘릴 수 있고 5를 넘기면 거부된다.
  Future<void> increment() => _todayDoc.set(
        {'count': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
}
