import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  test('Google Sign-In 네이티브 실패(PlatformException 10/12500)는 설정 오류 문구 + 로그 코드', () {
    expect(AuthErrors.message(PlatformException(code: '10', message: 'DEVELOPER_ERROR')), AuthErrors.setupError);
    expect(AuthErrors.message(PlatformException(code: '12500', message: 'SIGN_IN_FAILED')), AuthErrors.setupError);
    expect(AuthErrors.message(PlatformException(code: 'network_error')), AuthErrors.network);
    expect(AuthErrors.message(PlatformException(code: 'x', message: 'NetworK unreachable')), AuthErrors.network);
    expect(AuthErrors.code(PlatformException(code: '10', message: 'DEVELOPER_ERROR')), 'platform/10 DEVELOPER_ERROR');
    expect(AuthErrors.code(FirebaseAuthException(code: 'network-request-failed')), 'firebase/network-request-failed');
  });

  test('GoogleSignInException 설정 오류 → 설정 오류 문구, 취소 → 취소 문구', () {
    expect(AuthErrors.message(const GoogleSignInException(code: GoogleSignInExceptionCode.clientConfigurationError)), AuthErrors.setupError);
    expect(AuthErrors.message(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled)), contains('취소'));
    expect(AuthErrors.fromCode('provider-already-linked'), AuthErrors.alreadyLinked);
    expect(AuthErrors.fromCode('network-request-failed'), AuthErrors.network);
  });
}
