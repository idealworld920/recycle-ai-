import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'boot_report.dart';

/// Firebase 초기화 → App Check → 익명 로그인까지 한 번에 처리하고 상태를 알려준다.
///
/// 설정 파일이 자리표시자이거나 네트워크가 없어도 앱이 죽지 않도록
/// 각 단계를 따로 감싸고, 실패하면 [error] 에 담아 둔다.
class FirebaseSession extends ChangeNotifier {
  FirebaseSession._();

  /// 테스트나 Firebase 없는 환경용.
  FirebaseSession.unavailable([this._error = 'Firebase 설정이 없어요.']);

  /// 각 단계가 이보다 오래 걸리면 포기하고 오류로 기록한다. 앱은 그 전에 이미 홈에 가 있다.
  static const initTimeout = Duration(seconds: 10);
  static const signInTimeout = Duration(seconds: 15);
  static const probeTimeout = Duration(seconds: 8);

  bool _ready = false;
  String? _error;
  String? _firestoreError;
  bool _busy = false;
  final Completer<void> _settled = Completer<void>();
  StreamSubscription<User?>? _userSub;

  bool get ready => _ready;
  String? get error => _error;

  /// 로그인은 됐지만 Firestore 첫 읽기가 실패했을 때.
  String? get firestoreError => _firestoreError;
  bool get busy => _busy;
  String? get uid => _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  /// 첫 초기화 시도가 끝나면(성공이든 실패든) 완료된다. 스플래시가 이걸 기다린다.
  Future<void> get settled => _settled.future;

  /// 초기화를 시작만 하고 바로 돌려준다. 결과는 [ready]·[error] 와 [settled] 로 받는다.
  static FirebaseSession begin() {
    final s = FirebaseSession._();
    unawaited(s.init());
    return s;
  }

  /// 테스트용. 초기화를 기다렸다가 돌려준다.
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
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(initTimeout);
      }
      BootReport.mark('Firebase 초기화 끝');
      await _activateAppCheck();
      BootReport.mark('App Check 끝');
      _enableOfflineCache();
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously().timeout(signInTimeout);
      }
      BootReport.mark('익명 로그인 끝');
      _ready = FirebaseAuth.instance.currentUser != null;
      if (!_ready) _error = '익명 로그인에 실패했어요.';
      if (_ready) unawaited(_probeFirestore());
      // 구글 연결·로그아웃·삭제로 사용자가 바뀌면 알려서 저장소들이 다시 붙게 한다.
      _userSub ??= FirebaseAuth.instance.userChanges().listen((u) {
        _ready = u != null;
        notifyListeners();
      });
    } catch (e) {
      _ready = false;
      _error = _friendly(e);
      BootReport.mark('Firebase 실패: $e');
    } finally {
      _busy = false;
      if (!_settled.isCompleted) _settled.complete();
      notifyListeners();
    }
  }

  /// Firestore 첫 읽기. 실패해도 앱은 그대로 쓰고, 홈 배너로만 알린다.
  Future<void> _probeFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).get().timeout(probeTimeout);
      if (_firestoreError != null) {
        _firestoreError = null;
        notifyListeners();
      }
    } catch (e) {
      _firestoreError = _friendly(e);
      notifyListeners();
    }
  }

  /// `--dart-define=APP_CHECK=debug` 면 릴리스 빌드에서도 디버그 provider(에뮬레이터·사이드로드 테스트용),
  /// `APP_CHECK=off` 면 아예 켜지 않는다(콘솔에서 적용(enforce)이 꺼져 있을 때만 AI 가 동작).
  /// 비워 두면 디버그 빌드는 debug provider, 릴리스는 Play Integrity / App Attest.
  static const String appCheckMode = String.fromEnvironment('APP_CHECK');
  static bool get _useDebugProvider => appCheckMode == 'debug' || !kReleaseMode;

  String? _appCheckError;

  /// App Check 토큰을 못 받을 때. 이러면 AI 호출이 전부 거부된다.
  String? get appCheckError => _appCheckError;

  Future<void> _activateAppCheck() async {
    if (kIsWeb) return; // 웹은 reCAPTCHA 키 등록 후 켜요.
    if (appCheckMode == 'off') {
      BootReport.mark('App Check 꺼짐 (APP_CHECK=off)');
      return;
    }
    BootReport.mark(_useDebugProvider
        ? 'App Check: 디버그 provider (토큰은 logcat 태그 DebugAppCheckProvider 에 찍힘 → 콘솔에 등록)'
        : 'App Check: Play Integrity provider');
    try {
      await FirebaseAppCheck.instance
          .activate(
            providerAndroid: _useDebugProvider ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
            providerApple: _useDebugProvider ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
          )
          .timeout(const Duration(seconds: 5));
      unawaited(_probeAppCheck());
    } catch (e) {
      debugPrint('App Check 활성화 실패: $e');
    }
  }

  /// 토큰을 실제로 한 번 받아 본다. 실패하면 홈 배너로 알려서 "AI 가 왜 안 되지?" 를 바로 알 수 있게.
  Future<void> _probeAppCheck() async {
    try {
      await FirebaseAppCheck.instance.getToken().timeout(const Duration(seconds: 15));
      BootReport.mark('App Check 토큰 OK');
      if (_appCheckError != null) {
        _appCheckError = null;
        notifyListeners();
      }
    } catch (e) {
      BootReport.mark('App Check 토큰 실패: $e');
      _appCheckError = _useDebugProvider
          ? '디버그 토큰이 Firebase 콘솔에 등록돼 있지 않아요. logcat 의 "debug secret" 을 App Check → 앱 → 디버그 토큰 관리에 추가하세요.'
          : 'Play Integrity 인증에 실패했어요. 에뮬레이터·스토어 밖 설치본은 인증이 안 될 수 있어요. 콘솔 App Check 에 Play Integrity 와 SHA-256 이 등록돼 있는지 확인하세요.';
      notifyListeners();
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
    if (e is TimeoutException) return '연결이 너무 오래 걸려요. 인터넷을 확인해 주세요.';
    if (e is FirebaseException && e.plugin == 'cloud_firestore') {
      if (e.code == 'unavailable') return '서버에 연결하지 못했어요. 인터넷을 확인해 주세요.';
      if (e.code == 'permission-denied') return '데이터 접근이 거부됐어요. (보안 규칙·App Check 확인)';
      return 'Firestore 오류: ${e.message ?? e.code}';
    }
    if (e is FirebaseAuthException) {
      if (e.code == 'operation-not-allowed') return 'Firebase 콘솔에서 익명 로그인을 켜 주세요.';
      if (e.code == 'network-request-failed') return '인터넷 연결을 확인해 주세요.';
      return '로그인 오류: ${e.message ?? e.code}';
    }
    return '$e';
  }
}
