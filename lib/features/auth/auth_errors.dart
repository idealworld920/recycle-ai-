import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 인증 에러를 사용자 문구로 바꾼다.
class AuthErrors {
  AuthErrors._();

  static String message(Object e) {
    if (e is FirebaseAuthException) return fromCode(e.code);
    if (e is GoogleSignInException) {
      return switch (e.code) {
        GoogleSignInExceptionCode.canceled => '로그인을 취소했어요.',
        GoogleSignInExceptionCode.interrupted => '로그인이 중단됐어요. 다시 시도해 주세요.',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google 로그인 설정이 안 돼 있어요. Firebase 콘솔의 SHA 지문과 OAuth 설정을 확인해 주세요.',
        GoogleSignInExceptionCode.uiUnavailable => '지금은 로그인 화면을 열 수 없어요. 잠시 후 다시 시도해 주세요.',
        _ => 'Google 로그인에 실패했어요. 다시 시도해 주세요.',
      };
    }
    final s = e.toString();
    if (s.contains('network')) return '인터넷 연결을 확인해 주세요.';
    return '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
  }

  static String fromCode(String code) => switch (code) {
        'network-request-failed' => '인터넷 연결을 확인해 주세요.',
        'credential-already-in-use' || 'email-already-in-use' || 'account-exists-with-different-credential' =>
          '이 구글 계정은 이미 다른 ReSAI 기록에 연결돼 있어요.',
        'provider-already-linked' => '이미 구글 계정이 연결돼 있어요.',
        'requires-recent-login' => '보안을 위해 다시 로그인한 뒤 진행할 수 있어요.',
        'user-disabled' => '사용할 수 없는 계정이에요.',
        'user-not-found' || 'user-token-expired' => '로그인 정보가 만료됐어요. 다시 시도해 주세요.',
        'invalid-credential' => '로그인 정보가 올바르지 않아요. 다시 시도해 주세요.',
        'operation-not-allowed' => 'Firebase 콘솔에서 Google 로그인을 켜 주세요.',
        'too-many-requests' => '시도가 너무 많아요. 잠시 후 다시 해 주세요.',
        'web-context-canceled' || 'popup-closed-by-user' || 'cancelled-popup-request' => '로그인을 취소했어요.',
        _ => '로그인에 실패했어요. ($code)',
      };
}
