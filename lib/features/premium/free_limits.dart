import 'package:shared_preferences/shared_preferences.dart';

import '../chat/usage_repository.dart';

/// 무료 사용자의 하루 한도. 프리미엄이면 무제한.
class FreeLimits {
  FreeLimits(this._prefs);

  static const classifyPerDay = 5;
  static const chatPerDay = 3;
  static const _classifyPrefix = 'free_classify_';

  final SharedPreferences _prefs;

  String _todayKey() => '$_classifyPrefix${UsageRepository.dayKey(DateTime.now())}';

  int classifyCountToday() => _prefs.getInt(_todayKey()) ?? 0;

  bool get classifyExhausted => classifyCountToday() >= classifyPerDay;

  Future<void> incrementClassify() async {
    final key = _todayKey();
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    // 지난 날짜 키 정리
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_classifyPrefix) && k != key).toList()) {
      await _prefs.remove(k);
    }
  }
}
