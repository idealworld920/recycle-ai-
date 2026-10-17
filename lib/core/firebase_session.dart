import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Firebase 초기화 → App Check → 익명 로그인까지 한 번에 처리하고 상태를 알려준다.
///
/// 설정 파일이 자리표시자이거나 네트워크가 없어도 앱이 죽지 않도록
/// 각 단계를 따로 감싸고, 실패하면 [error] 에 담아 둔다.
class FirebaseSession extends ChangeNotifier {
  FirebaseSession._();

  /// 테스트나 Firebase 없는 환경용.
  FirebaseSession.unavailable([this._error = 'Firebase 설정이 없어요.']);

  bool _ready = false;
  String? _error;
  bool _busy = false;
  StreamSubscription<User?>? _userSub;

  bool get ready => _ready;
  String? get error => _error;
  bool get busy => _busy;
  String? get uid => _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  static Future<FirebaseSession> start() async {
    final s = FirebaseSession._();
    await s.init();
    return s;
  }

  Future<void> init() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (DefaultFirebaseOptions.currentPlatform.projectId == 'placeholder') {
        throw StateError('firebase_options.dart 가 자리표시자예요. flutterfire configure 를 실행하세요.');
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      await _activateAppCheck();
      _enableOfflineCache();
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      _ready = FirebaseAuth.instance.currentUser != null;
      if (!_ready) _error = '익명 로그인에 실패했어요.';
      // 구글 연결·로그아웃·삭제로 사용자가 바뀌면 알려서 저장소들이 다시 붙게 한다.
      _userSub ??= FirebaseAuth.instance.userChanges().listen((u) {
        _ready = u != null;
        notifyListeners();
      });
    } catch (e) {
      _ready = false;
      _error = _friendly(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// 디버그 빌드는 debug provider, 릴리스는 Play Integrity / App Attest.
  Future<void> _activateAppCheck() async {
    if (kIsWeb) return; // 웹은 reCAPTCHA 키 등록 후 켜요.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode ? const AndroidPlayIntegrityProvider() : const AndroidDebugProvider(),
        providerApple: kReleaseMode ? const AppleAppAttestWithDeviceCheckFallbackProvider() : const AppleDebugProvider(),
      );
    } catch (e) {
      debugPrint('App Check 활성화 실패: $e');
    }
  }

  void _enableOfflineCache() {
    try {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Firestore 오프라인 캐시 설정 실패: $e');
    }
  }

  static String _friendly(Object e) {
    if (e is FirebaseAuthException) {
      if (e.code == 'operation-not-allowed') return 'Firebase 콘솔에서 익명 로그인을 켜 주세요.';
      if (e.code == 'network-request-failed') return '인터넷 연결을 확인해 주세요.';
      return '로그인 오류: ${e.message ?? e.code}';
    }
    return '$e';
  }
}
