import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase_session.dart';

/// 연결 시도 결과.
sealed class LinkOutcome {
  const LinkOutcome();
}

class LinkSuccess extends LinkOutcome {
  const LinkSuccess();
}

class LinkCancelled extends LinkOutcome {
  const LinkCancelled();
}

/// 그 구글 계정에 이미 다른 ReSAI 사용자가 묶여 있음. [credential] 로 그 계정으로 전환할 수 있다.
class LinkAlreadyInUse extends LinkOutcome {
  const LinkAlreadyInUse(this.credential, this.email);
  final AuthCredential credential;
  final String? email;
}

class LinkFailed extends LinkOutcome {
  const LinkFailed(this.error);
  final Object error;
}

/// Firebase Auth + Google 로그인 래퍼. 화면은 [AuthStore] 를 통해 쓴다.
abstract class AuthService {
  User? get currentUser;
  Stream<User?> get userChanges;
  Future<LinkOutcome> linkGoogle();
  Future<LinkOutcome> signInWithCredential(AuthCredential credential);
  Future<void> signOutAndStartAnonymous();
  Future<void> deleteAccount();

  /// users/{uid} 문서 필드 병합.
  Future<void> mergeUserDoc(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> readUserDoc();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;
  bool _googleReady = false;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get userChanges => _auth.userChanges();

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await _google.initialize();
    _googleReady = true;
  }

  Future<AuthCredential> _googleCredential() async {
    await _ensureGoogle();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential', message: 'Google idToken 이 없어요. serverClientId 설정을 확인하세요.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<LinkOutcome> linkGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return const LinkFailed('로그인 상태가 아니에요.');
    AuthCredential credential;
    try {
      credential = await _googleCredential();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return const LinkCancelled();
      return LinkFailed(e);
    } catch (e) {
      return LinkFailed(e);
    }
    try {
      await user.linkWithCredential(credential);
      await _afterLink();
      return const LinkSuccess();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use' || e.code == 'account-exists-with-different-credential') {
        return LinkAlreadyInUse(e.credential ?? credential, e.email);
      }
      if (e.code == 'provider-already-linked') return const LinkSuccess();
      return LinkFailed(e);
    } catch (e) {
      return LinkFailed(e);
    }
  }

  @override
  Future<LinkOutcome> signInWithCredential(AuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      await _afterLink();
      return const LinkSuccess();
    } catch (e) {
      return LinkFailed(e);
    }
  }

  Future<void> _afterLink() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await mergeUserDoc({
      'linkedAt': FieldValue.serverTimestamp(),
      'email': user.email,
      'provider': 'google',
    });
  }

  @override
  Future<void> signOutAndStartAnonymous() async {
    try {
      await _ensureGoogle();
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _deleteUserData(uid);
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      final credential = await _googleCredential();
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    }
    try {
      await _ensureGoogle();
      await _google.signOut();
    } catch (_) {}
    await _auth.signInAnonymously();
  }

  static const _subcollections = ['history', 'checkins', 'collection', 'settings', 'usage'];

  /// users/{uid} 아래 데이터 전부 삭제. 하위 컬렉션은 동시에, 각각 400개씩 배치.
  Future<void> _deleteUserData(String uid) async {
    final userDoc = _db.collection('users').doc(uid);
    await Future.wait(_subcollections.map((name) => _deleteCollection(userDoc.collection(name))));
    await userDoc.delete();
  }

  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> col) async {
    while (true) {
      final snap = await col.limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 400) break;
    }
  }

  @override
  Future<void> mergeUserDoc(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('users 문서 저장 실패: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> readUserDoc() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      return (await _db.collection('users').doc(uid).get()).data();
    } catch (_) {
      return null;
    }
  }
}

/// Firebase 없이 돌 때(테스트, 설정 전). 항상 익명으로 본다.
/// Firebase 가 아직(또는 끝내) 준비되지 않아도 앱이 뜨도록, 준비되는 순간부터
/// [FirebaseAuthService] 로 넘어가는 위임 서비스. 그 전엔 [OfflineAuthService] 처럼 동작한다.
class SessionAuthService implements AuthService {
  SessionAuthService(this._session) {
    _session.addListener(_onSession);
    _onSession();
  }

  final FirebaseSession _session;
  final OfflineAuthService _offline = OfflineAuthService();
  final StreamController<User?> _changes = StreamController<User?>.broadcast();
  FirebaseAuthService? _firebase;
  StreamSubscription<User?>? _sub;

  AuthService get _delegate => _firebase ?? _offline;

  void _onSession() {
    if (!_session.ready || _firebase != null) return;
    _firebase = FirebaseAuthService();
    _sub = _firebase!.userChanges.listen(_changes.add, onError: (_) {});
    _changes.add(_firebase!.currentUser);
  }

  @override
  User? get currentUser => _delegate.currentUser;

  @override
  Stream<User?> get userChanges => _changes.stream;

  @override
  Future<LinkOutcome> linkGoogle() => _delegate.linkGoogle();

  @override
  Future<LinkOutcome> signInWithCredential(AuthCredential credential) => _delegate.signInWithCredential(credential);

  @override
  Future<void> signOutAndStartAnonymous() => _delegate.signOutAndStartAnonymous();

  @override
  Future<void> deleteAccount() => _delegate.deleteAccount();

  @override
  Future<void> mergeUserDoc(Map<String, dynamic> data) => _delegate.mergeUserDoc(data);

  @override
  Future<Map<String, dynamic>?> readUserDoc() => _delegate.readUserDoc();

  void dispose() {
    _session.removeListener(_onSession);
    _sub?.cancel();
    _changes.close();
  }
}

class OfflineAuthService implements AuthService {
  @override
  User? get currentUser => null;
  @override
  Stream<User?> get userChanges => const Stream.empty();
  @override
  Future<LinkOutcome> linkGoogle() async => const LinkFailed('Firebase 가 연결돼 있지 않아요.');
  @override
  Future<LinkOutcome> signInWithCredential(AuthCredential credential) async => const LinkFailed('Firebase 가 연결돼 있지 않아요.');
  @override
  Future<void> signOutAndStartAnonymous() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> mergeUserDoc(Map<String, dynamic> data) async {}
  @override
  Future<Map<String, dynamic>?> readUserDoc() async => null;
}
