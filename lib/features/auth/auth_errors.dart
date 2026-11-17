import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 인증 에러를 사용자 문구로 바꾼다. 로그용 코드는 [code].
class AuthErrors {
  AuthErrors._();

  static const setupError = '로그인 설정 오류예요. 잠시 후 다시 시도해 주세요';
  static const network = '인터넷 연결을 확인해 주세요';
  static const alreadyLinked = '이미 연결돼 있어요';

  /// 분석용 코드: 메시지 없이 코드만 (이메일 등 개인정보가 섞일 수 있는 설명은 뺀다).
  static String shortCode(Object e) {
    if (e is FirebaseAuthException) return 'firebase/${e.code}';
    if (e is GoogleSignInException) return 'google/${e.code.name}';
    if (e is PlatformException) return 'platform/${e.code}';
    return e.runtimeType.toString();
  }

  /// 로그에 남길 짧은 코드.
  static String code(Object e) {
    if (e is FirebaseAuthException) return 'firebase/${e.code}';
    if (e is GoogleSignInException) return 'google/${e.code.name}${e.description == null ? '' : ' ${e.description}'}';
    if (e is PlatformException) return 'platform/${e.code}${e.message == null ? '' : ' ${e.message}'}';
    return e.runtimeType.toString();
  }

  static String message(Object e) {
    if (e is FirebaseAuthException) return fromCode(e.code);
    if (e is GoogleSignInException) {
      return switch (e.code) {
        GoogleSignInExceptionCode.canceled => '로그인을 취소했어요.',
        GoogleSignInExceptionCode.interrupted => '로그인이 중단됐어요. 다시 시도해 주세요.',
        GoogleSignInExceptionCode.clientConfigurationError || GoogleSignInExceptionCode.providerConfigurationError => setupError,
        GoogleSignInExceptionCode.uiUnavailable => '지금은 로그인 화면을 열 수 없어요. 잠시 후 다시 시도해 주세요.',
        _ => _networkOr(e.description, setupError),
      };
    }
    // Google Sign-In 네이티브 실패 (10 DEVELOPER_ERROR, 12500 SIGN_IN_FAILED, 7 NETWORK_ERROR …)
    if (e is PlatformException) {
      if (e.code == 'network_error' || e.code == '7') return network;
      if (e.code == 'sign_in_canceled' || e.code == '12501') return '로그인을 취소했어요.';
      return _networkOr(e.message, setupError);
    }
    return _networkOr(e.toString(), '문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
  }

  static String _networkOr(String? s, String fallback) {
    final t = (s ?? '').toLowerCase();
    if (t.contains('network') || t.contains('unreachable') || t.contains('timeout')) return network;
    return fallback;
  }

  static String fromCode(String code) => switch (code) {
        'network-request-failed' => network,
        'credential-already-in-use' || 'email-already-in-use' || 'account-exists-with-different-credential' =>
          '이 Google 계정은 이미 다른 ReSAI 기록에 연결돼 있어요.',
        'provider-already-linked' => alreadyLinked,
        'requires-recent-login' => '보안을 위해 다시 로그인한 뒤 진행할 수 있어요.',
        'user-disabled' => '사용할 수 없는 계정이에요.',
        'user-not-found' || 'user-token-expired' => '로그인 정보가 만료됐어요. 다시 시도해 주세요.',
        'invalid-credential' => setupError,
        'operation-not-allowed' => 'Firebase 콘솔에서 Google 로그인을 켜 주세요.',
        'too-many-requests' => '시도가 너무 많아요. 잠시 후 다시 해 주세요.',
        'web-context-canceled' || 'popup-closed-by-user' || 'cancelled-popup-request' => '로그인을 취소했어요.',
        _ => '로그인에 실패했어요. ($code)',
      };
}
