import '../schedule/pickup_schedule.dart';

class Household {
  const Household({
    required this.id,
    required this.code,
    required this.ownerUid,
    required this.name,
    required this.memberUids,
    this.schedule,
  });

  final String id;
  final String code;
  final String ownerUid;
  final String name;
  final List<String> memberUids;
  final PickupSchedule? schedule;

  factory Household.fromJson(String id, Map<String, dynamic> j) => Household(
        id: id,
        code: (j['code'] ?? '') as String,
        ownerUid: (j['ownerUid'] ?? '') as String,
        name: (j['name'] ?? '우리 집') as String,
        memberUids: ((j['memberUids'] as List?) ?? const []).map((e) => e.toString()).toList(growable: false),
        schedule: j['schedule'] is Map ? PickupSchedule.fromJson((j['schedule'] as Map).cast<String, dynamic>()) : null,
      );
}

class HouseholdMember {
  const HouseholdMember({required this.uid, required this.nickname});

  final String uid;
  final String nickname;
}

/// 집 단위 체크인 한 건: 누가 언제.
class MemberCheckin {
  const MemberCheckin({required this.uid, required this.nickname, required this.at});

  final String uid;
  final String nickname;
  final DateTime at;

  String get timeLabel => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}
