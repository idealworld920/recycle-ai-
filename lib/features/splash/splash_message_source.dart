import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'splash_plan.dart';

/// Remote Config 에서 `splash_message` 를 읽는다.
///
/// 스플래시를 기다리게 하지 않으려고: 지난번에 fetch 해 둔 값을 [activate] 로 즉시 쓰고, 이번 [fetch] 는 다음 실행을 위해 백그라운드로.
class SplashMessageSource {
  SplashMessageSource._();

  static const key = 'splash_message';

  static Future<SplashMessage?> readCached() async {
    if (kIsWeb) return null;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.activate();
      final raw = rc.getString(key);
      if (raw.isEmpty) return null;
      return SplashMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('splash_message 읽기 실패: $e');
      return null;
    }
  }

  /// 다음 실행을 위한 fetch. 실패해도 조용히.
  static Future<void> prefetch() async {
    if (kIsWeb) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(seconds: 5), minimumFetchInterval: const Duration(hours: 1)));
      await rc.fetch();
    } catch (e) {
      debugPrint('splash_message fetch 실패: $e');
    }
  }
}
