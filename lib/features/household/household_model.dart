import 'package:cloud_firestore/cloud_firestore.dart';

import '../schedule/pickup_schedule.dart';

/// 가족 공유 집. households/{id}
///
/// { name, ownerUid, memberUids:[uid], members:[{uid,nickname,color,joinedAt}], inviteCode, inviteCodeExpiresAt,
///   schedule, premiumUntil, createdAt }
/// memberUids 는 규칙(in 검사)용 중복 필드, members 가 표시용 진실.
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.members,
    this.inviteCode = '',
    this.inviteCodeExpiresAt,
    this.schedule,
    this.premiumUntil,
  });

  static const maxMembers = 6;

  final String id;
  final String name;
  final String ownerUid;
  final List<HouseholdMember> members;
  final String inviteCode;
  final DateTime? inviteCodeExpiresAt;
  final PickupSchedule? schedule;

  /// 방장 구독으로 열린 가족 플랜 만료 시각 (RevenueCat 웹훅 → Cloud Function 만 쓴다).
  final DateTime? premiumUntil;

  List<String> get memberUids => members.map((m) => m.uid).toList(growable: false);
  bool isOwner(String? uid) => uid != null && uid == ownerUid;
  bool get isFull => members.length >= maxMembers;
  HouseholdMember? member(String? uid) => members.where((m) => m.uid == uid).firstOrNull;

  bool inviteExpiredAt(DateTime now) => inviteCodeExpiresAt == null || !now.isBefore(inviteCodeExpiresAt!);

  /// 가족 플랜이 지금 살아 있는가 (멤버 전원에게 적용).
  bool premiumActiveAt(DateTime now) => premiumUntil != null && now.isBefore(premiumUntil!);

  factory Household.fromJson(String id, Map<String, dynamic> j) {
    final members = ((j['members'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => HouseholdMember.fromJson(m.cast<String, dynamic>()))
        .toList(growable: false);
    return Household(
      id: id,
      name: (j['name'] ?? '우리 집') as String,
      ownerUid: (j['ownerUid'] ?? '') as String,
      members: members,
      inviteCode: (j['inviteCode'] ?? '') as String,
      inviteCodeExpiresAt: _date(j['inviteCodeExpiresAt']),
      schedule: j['schedule'] is Map ? PickupSchedule.fromJson((j['schedule'] as Map).cast<String, dynamic>()) : null,
      premiumUntil: _date(j['premiumUntil']),
    );
  }

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class HouseholdMember {
  const HouseholdMember({required this.uid, required this.nickname, this.color = 0, this.joinedAt});

  final String uid;
  final String nickname;

  /// 자동 배정 색 번호 0~5 ([memberColorCount]). 화면에서 토큰 팔레트로 바꾼다.
  final int color;
  final DateTime? joinedAt;

  static const memberColorCount = 6;

  factory HouseholdMember.fromJson(Map<String, dynamic> j) => HouseholdMember(
        uid: (j['uid'] ?? '') as String,
        nickname: (j['nickname'] ?? '') as String,
        color: (j['color'] as num?)?.toInt().clamp(0, memberColorCount - 1) ?? 0,
        joinedAt: Household._date(j['joinedAt']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'color': color,
        'joinedAt': joinedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      };

  /// 아직 안 쓰인 색 중 첫 번째. 다 썼으면 인원수 기준 순환.
  static int nextColor(Iterable<HouseholdMember> existing) {
    final used = existing.map((m) => m.color).toSet();
    for (var i = 0; i < memberColorCount; i++) {
      if (!used.contains(i)) return i;
    }
    return existing.length % memberColorCount;
  }

  /// 구글 이름 앞 2글자. 없으면 "나".
  static String defaultNickname(String? displayName) {
    final s = (displayName ?? '').trim();
    if (s.isEmpty) return '나';
    return s.runes.length <= 2 ? s : String.fromCharCodes(s.runes.take(2));
  }
}

/// 집 단위 체크인 한 건: 누가 언제.
class MemberCheckin {
  const MemberCheckin({required this.uid, required this.nickname, required this.at});

  final String uid;
  final String nickname;
  final DateTime at;

  String get timeLabel => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}
