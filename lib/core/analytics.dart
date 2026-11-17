import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Firebase Analytics 얇은 래퍼. Firebase 가 준비 안 됐거나 실패해도 앱 흐름을 막지 않는다.
///
/// 원칙: 사진·채팅 본문·이메일·정확한 위치 같은 개인정보는 어떤 이벤트에도 넣지 않는다.
/// 파라미터는 String/num/bool 만 보내고, 디버그 빌드에서는 전부 `[A]` 로그로 찍는다.
/// `--dart-define=ANALYTICS_DISABLED=true` 면 수집을 끈다 (테스터 기기용).
class Analytics {
  Analytics._();

  static const disabledByBuild = bool.fromEnvironment('ANALYTICS_DISABLED');

  static bool _collectionConfigured = false;
  static final Map<String, String?> _userProps = {};
  static final Map<String, String> _screenNames = {};

  /// 테스트에서 가로채기용. null 이면 Firebase 로 간다.
  @visibleForTesting
  static void Function(String name, Map<String, Object>? params)? sink;
  @visibleForTesting
  static final List<(String, Map<String, Object>?)> recorded = [];
  @visibleForTesting
  static bool record = false;

  static bool get _ready => Firebase.apps.isNotEmpty;

  /// Firebase 가 준비된 뒤 한 번: 수집 on/off 반영.
  static Future<void> configureCollection() async {
    if (_collectionConfigured || !_ready) return;
    _collectionConfigured = true;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!disabledByBuild);
      if (disabledByBuild) debugPrint('[A] 수집 꺼짐 (ANALYTICS_DISABLED)');
    } catch (e) {
      debugPrint('[A] collection 설정 실패: $e');
    }
  }

  /// 이벤트. 값은 String/num/bool 만, 나머지는 toString. null 은 뺀다.
  static Future<void> log(String name, [Map<String, Object?>? params]) async {
    final clean = sanitize(params);
    if (kDebugMode) debugPrint('[A] $name ${clean ?? ''}');
    if (record) recorded.add((name, clean));
    if (sink != null) {
      sink!(name, clean);
      return;
    }
    if (!_ready) return;
    try {
      await configureCollection();
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: clean);
    } catch (e) {
      debugPrint('[A] $name 실패: $e');
    }
  }

  /// 바텀시트·오버레이처럼 라우트가 아닌 화면.
  static Future<void> screen(String screenName) async {
    if (kDebugMode) debugPrint('[A] screen_view $screenName');
    if (record) recorded.add(('screen_view', {'screen_name': screenName}));
    if (sink != null) {
      sink!('screen_view', {'screen_name': screenName});
      return;
    }
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[A] screen $screenName 실패: $e');
    }
  }

  /// 사용자 속성. 같은 값이면 다시 보내지 않는다.
  static Future<void> setUserProperty(String name, String? value) async {
    if (_userProps.containsKey(name) && _userProps[name] == value) return;
    _userProps[name] = value;
    if (kDebugMode) debugPrint('[A] user_property $name=$value');
    if (sink != null || !_ready) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('[A] user_property $name 실패: $e');
    }
  }

  static Future<void> setUserProperties(Map<String, String?> props) async {
    for (final e in props.entries) {
      await setUserProperty(e.key, e.value);
    }
  }

  @visibleForTesting
  static Map<String, String?> get userPropertiesSent => Map.unmodifiable(_userProps);

  @visibleForTesting
  static void resetForTest() {
    _userProps.clear();
    recorded.clear();
  }

  static Map<String, Object>? sanitize(Map<String, Object?>? params) {
    if (params == null) return null;
    final out = <String, Object>{};
    for (final e in params.entries) {
      final v = e.value;
      if (v == null) continue;
      if (v is String || v is num) {
        out[e.key] = v;
      } else if (v is bool) {
        out[e.key] = v.toString(); // GA4 는 bool 파라미터를 문자열로 받는 편이 안전
      } else if (v is Enum) {
        out[e.key] = v.name;
      } else {
        out[e.key] = v.toString();
      }
    }
    return out;
  }

  // ---- 버킷 헬퍼 (숫자 대신 구간으로 보내 개인 식별을 어렵게) ----
  static String confidenceBucket(double c) => c < 0.6 ? 'low' : c < 0.85 ? 'mid' : 'high';
  static String lengthBucket(int chars) => chars <= 20 ? 'short' : chars <= 80 ? 'mid' : 'long';
  static String collectionBucket(int n) => n <= 0 ? '0' : n < 10 ? '1-9' : n < 30 ? '10-29' : n < 56 ? '30-55' : '56';
  static String installAgeBucket(int days) => days <= 0 ? '0' : days <= 3 ? '1-3' : days <= 7 ? '4-7' : days <= 30 ? '8-30' : '30+';

  /// 라우트 위젯 타입 → 화면 이름 (ResultScreen → result_screen).
  static String screenNameOf(Object page) {
    final type = page.runtimeType.toString();
    return _screenNames.putIfAbsent(type, () => type.replaceAllMapped(RegExp(r'(?<=[a-z0-9])[A-Z]'), (m) => '_${m[0]}').toLowerCase());
  }
}

/// 라우트 전환마다 screen_view (FirebaseAnalyticsObserver 와 같은 일을 하되 Firebase 가 뒤늦게 준비돼도 안전하다:
/// logScreenView 는 준비 전 호출을 조용히 건너뛴다). 화면 이름은 라우트 settings.name, 없으면 [AppPageRoute] 의 위젯 타입.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  String? _nameOf(Route<dynamic> route) {
    final n = route.settings.name;
    if (n != null && n.isNotEmpty && n != '/') return n;
    return route is AnalyticsRoute ? (route as AnalyticsRoute).analyticsName : null;
  }

  void _send(Route<dynamic>? route) {
    if (route == null || route is! PageRoute) return;
    final name = _nameOf(route);
    if (name != null) unawaited(Analytics.screen(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _send(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _send(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _send(newRoute);
}

/// 화면 이름을 가진 라우트 (AppPageRoute 가 구현).
abstract class AnalyticsRoute {
  String get analyticsName;
}
