import 'dart:async';

import 'package:flutter/foundation.dart';

/// 앱 시작 단계에서 생긴 문제 모음. 어떤 단계가 실패해도 앱은 홈까지 가고,
/// 홈에서 작은 배너로 이유만 알려준다.
class BootReport extends ChangeNotifier {
  BootReport({this.silent = false});

  /// 스크린샷용 데모 빌드처럼 배너를 아예 안 보여줄 때.
  final bool silent;
  final List<BootIssue> _issues = [];
  bool _dismissed = false;

  List<BootIssue> get issues => List.unmodifiable(_issues);
  bool get hasIssues => _issues.isNotEmpty;
  bool get dismissed => _dismissed;

  /// 진행 표시. 릴리스에서도 logcat(flutter 태그)에 남아서 어디서 멈췄는지 알 수 있다.
  static void mark(String step) {
    // ignore: avoid_print
    print('[boot] $step');
  }

  void add(String step, Object error) {
    // ignore: avoid_print
    print('[boot] $step 실패: $error');
    _issues.removeWhere((i) => i.step == step);
    _issues.add(BootIssue(step, _shorten(error)));
    _dismissed = false;
    notifyListeners();
  }

  void remove(String step) {
    if (_issues.any((i) => i.step == step)) {
      _issues.removeWhere((i) => i.step == step);
      notifyListeners();
    }
  }

  void dismiss() {
    _dismissed = true;
    notifyListeners();
  }

  /// 한 단계를 감싼다. 실패하거나 [timeout] 을 넘기면 기록하고 [fallback] 을 돌려준다.
  Future<T> guard<T>(String step, Future<T> Function() run, {required T Function() fallback, Duration? timeout}) async {
    try {
      final f = run();
      return await (timeout == null ? f : f.timeout(timeout));
    } catch (e) {
      add(step, e);
      return fallback();
    }
  }

  /// 결과가 필요 없는 단계용.
  Future<void> run(String step, Future<void> Function() action, {Duration? timeout}) =>
      guard<void>(step, action, fallback: () {}, timeout: timeout);

  static String _shorten(Object e) {
    if (e is TimeoutException) return '응답이 너무 오래 걸려요.';
    final s = '$e'.replaceFirst(RegExp(r'^(Bad state|Exception|Error|\w+(Exception|Error)):\s*'), '');
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}

class BootIssue {
  const BootIssue(this.step, this.message);

  final String step;
  final String message;

  @override
  String toString() => '$step: $message';
}
