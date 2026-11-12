import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 얇은 래퍼. Firebase 가 준비 안 됐거나 실패해도 앱 흐름을 막지 않는다.
class Analytics {
  Analytics._();

  static Future<void> log(String name, [Map<String, Object>? params]) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('analytics $name 실패: $e');
    }
  }
}
