import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/auth/auth_errors.dart';

void main() {
  test('주요 코드가 사용자 문구로 바뀐다', () {
    expect(AuthErrors.fromCode('network-request-failed'), contains('인터넷'));
    expect(AuthErrors.fromCode('credential-already-in-use'), contains('이미'));
    expect(AuthErrors.fromCode('requires-recent-login'), contains('다시 로그인'));
    expect(AuthErrors.fromCode('operation-not-allowed'), contains('콘솔'));
    expect(AuthErrors.fromCode('something-else'), contains('something-else'));
  });

  test('FirebaseAuthException 도 매핑된다', () {
    expect(AuthErrors.message(FirebaseAuthException(code: 'user-disabled')), contains('사용할 수 없는'));
  });

  test('알 수 없는 에러는 일반 문구', () {
    expect(AuthErrors.message(StateError('x')), contains('문제가 생겼어요'));
  });
}
