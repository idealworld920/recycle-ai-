import 'dart:math';

/// 집 초대 코드: 6자리 영숫자, 헷갈리는 0/O/1/I 제외, 대소문자 무시, 24시간 유효.
class InviteCode {
  InviteCode._();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 6;
  static const validity = Duration(hours: 24);

  static String generate([Random? rnd]) {
    final r = rnd ?? Random.secure();
    return String.fromCharCodes(List.generate(length, (_) => alphabet.codeUnitAt(r.nextInt(alphabet.length))));
  }

  /// 입력 정리: 공백·하이픈 제거, 대문자화. 0→O, 1→I 같은 치환은 하지 않는다 (애초에 없는 글자).
  static String normalize(String input) => input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  static bool isValid(String code) => code.length == length && code.split('').every(alphabet.contains);

  static DateTime expiryFrom(DateTime now) => now.add(validity);
}
