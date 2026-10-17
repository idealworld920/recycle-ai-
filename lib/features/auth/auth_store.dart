import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// 로그인 상태 + "한 번만" 보여주는 유도 배너 기록.
class AuthStore extends ChangeNotifier {
  AuthStore(this._service, this._prefs, {this.demoLinked = false}) {
    _sub = _service.userChanges.listen((_) {
      _loadPromptState();
      notifyListeners();
    });
  }

  static const promptPrefPrefix = 'prompt_dismissed_';
  static const keyHistory10 = 'history10';
  static const keyHistory30 = 'history30';

  final AuthService _service;
  final SharedPreferences _prefs;

  /// 스크린샷·데모 빌드에서 잠금 UI 없이 보이게.
  final bool demoLinked;
  StreamSubscription<User?>? _sub;
  Map<String, bool> _dismissed = {};
  bool _busy = false;

  AuthService get service => _service;
  User? get user => _service.currentUser;
  String? get uid => user?.uid;
  bool get busy => _busy;

  /// 익명이거나 아예 로그인 전이면 true.
  bool get isAnonymous => demoLinked ? false : (user?.isAnonymous ?? true);
  bool get isLinked => !isAnonymous;
  String? get email => user?.email;

  static Future<AuthStore> load(AuthService service, {bool demoLinked = false}) async {
    final s = AuthStore(service, await SharedPreferences.getInstance(), demoLinked: demoLinked);
    await s._loadPromptState();
    return s;
  }

  bool isDismissed(String key) => _dismissed[key] == true || (_prefs.getBool('$promptPrefPrefix$key') ?? false);

  /// 닫으면 users/{uid}.promptDismissed.{key} 와 기기에 기록.
  Future<void> dismissPrompt(String key) async {
    _dismissed = {..._dismissed, key: true};
    await _prefs.setBool('$promptPrefPrefix$key', true);
    notifyListeners();
    await _service.mergeUserDoc({'promptDismissed': {key: true}});
  }

  Future<void> _loadPromptState() async {
    final doc = await _service.readUserDoc();
    final remote = (doc?['promptDismissed'] as Map?)?.map((k, v) => MapEntry(k.toString(), v == true)) ?? const {};
    if (remote.isNotEmpty) {
      _dismissed = {..._dismissed, ...remote};
      notifyListeners();
    }
  }

  Future<LinkOutcome> linkGoogle() => _run(_service.linkGoogle);

  Future<LinkOutcome> switchToExisting(AuthCredential credential) => _run(() => _service.signInWithCredential(credential));

  Future<LinkOutcome> _run(Future<LinkOutcome> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      final r = await action();
      if (r is LinkSuccess) await _loadPromptState();
      return r;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOutToAnonymous() async {
    _busy = true;
    notifyListeners();
    try {
      await _service.signOutAndStartAnonymous();
      _clearLocalPrompts();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _busy = true;
    notifyListeners();
    try {
      await _service.deleteAccount();
      _clearLocalPrompts();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _clearLocalPrompts() {
    _dismissed = {};
    for (final k in _prefs.getKeys().where((k) => k.startsWith(promptPrefPrefix))) {
      _prefs.remove(k);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
