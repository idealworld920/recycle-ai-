import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/household/household_model.dart';
import 'package:recycle_ai/features/household/invite_code.dart';

void main() {
  group('초대 코드', () {
    test('6자리, 헷갈리는 글자(0/O/1/I) 없음', () {
      for (var i = 0; i < 200; i++) {
        final c = InviteCode.generate();
        expect(c.length, 6);
        expect(InviteCode.isValid(c), isTrue);
        expect(c.contains(RegExp('[0O1I]')), isFalse);
      }
    });

    test('입력 정리: 소문자·공백·하이픈 허용, 잘못된 글자는 거부', () {
      expect(InviteCode.normalize(' ab c-d2 3 '), 'ABCD23');
      expect(InviteCode.isValid(InviteCode.normalize('abcd23')), isTrue);
      expect(InviteCode.isValid('ABC012'), isFalse); // 0 과 1 은 없는 글자
      expect(InviteCode.isValid('ABCDE'), isFalse);
    });

    test('24시간 유효', () {
      final now = DateTime(2026, 11, 14, 10);
      expect(InviteCode.expiryFrom(now), DateTime(2026, 11, 15, 10));
    });
  });

  group('집 모델', () {
    final json = {
      'name': '우리 집',
      'ownerUid': 'a',
      'memberUids': ['a', 'b'],
      'members': [
        {'uid': 'a', 'nickname': '엄마', 'color': 0, 'joinedAt': 1000},
        {'uid': 'b', 'nickname': '민수', 'color': 1, 'joinedAt': 2000},
      ],
      'inviteCode': 'ABCD23',
      'inviteCodeExpiresAt': DateTime(2026, 11, 15).millisecondsSinceEpoch,
      'premiumUntil': DateTime(2026, 12, 1).millisecondsSinceEpoch,
    };

    test('파싱·방장·정원·만료·가족 플랜', () {
      final h = Household.fromJson('h1', json);
      expect(h.members.length, 2);
      expect(h.memberUids, ['a', 'b']);
      expect(h.isOwner('a'), isTrue);
      expect(h.isOwner('b'), isFalse);
      expect(h.isFull, isFalse);
      expect(h.inviteExpiredAt(DateTime(2026, 11, 14, 23)), isFalse);
      expect(h.inviteExpiredAt(DateTime(2026, 11, 15, 0, 1)), isTrue);
      expect(h.premiumActiveAt(DateTime(2026, 11, 20)), isTrue);
      expect(h.premiumActiveAt(DateTime(2026, 12, 2)), isFalse);
      expect(h.member('b')!.nickname, '민수');
    });

    test('premiumUntil 없으면 가족 플랜 아님, 코드 없으면 만료 취급', () {
      final h = Household.fromJson('h', {'ownerUid': 'a', 'members': []});
      expect(h.premiumActiveAt(DateTime.now()), isFalse);
      expect(h.inviteExpiredAt(DateTime.now()), isTrue);
    });

    test('최대 6명', () {
      final six = Household.fromJson('h', {
        'ownerUid': 'u0',
        'members': [for (var i = 0; i < 6; i++) {'uid': 'u$i', 'nickname': '멤버$i', 'color': i}],
      });
      expect(six.isFull, isTrue);
    });
  });

  group('멤버', () {
    test('색은 안 쓰인 것부터, 다 쓰면 순환', () {
      final ms = [for (var i = 0; i < 3; i++) HouseholdMember(uid: '$i', nickname: '', color: i)];
      expect(HouseholdMember.nextColor(ms), 3);
      final six = [for (var i = 0; i < 6; i++) HouseholdMember(uid: '$i', nickname: '', color: i)];
      expect(HouseholdMember.nextColor(six), 0);
      expect(HouseholdMember.nextColor([HouseholdMember(uid: 'x', nickname: '', color: 2)]), 0);
    });

    test('기본 닉네임은 구글 이름 앞 2글자', () {
      expect(HouseholdMember.defaultNickname('홍길동'), '홍길');
      expect(HouseholdMember.defaultNickname('Kim Minsu'), 'Ki');
      expect(HouseholdMember.defaultNickname('나'), '나');
      expect(HouseholdMember.defaultNickname(null), '나');
      expect(HouseholdMember.defaultNickname('  '), '나');
    });

    test('toJson 왕복', () {
      final m = HouseholdMember(uid: 'u', nickname: '아빠', color: 4, joinedAt: DateTime(2026, 1, 1));
      final back = HouseholdMember.fromJson(m.toJson());
      expect(back.uid, 'u');
      expect(back.color, 4);
      expect(back.joinedAt, DateTime(2026, 1, 1));
    });
  });
}
