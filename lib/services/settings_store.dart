import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장소. AI 호출은 Firebase 를 통하므로 API 키는 더 이상 다루지 않는다.
class SettingsStore {
  SettingsStore(this._prefs);

  static const _onboardedPref = 'onboarded_v1';
  static const _quizReminderPref = 'quiz_reminder_v1';
  static const _installedAtPref = 'installed_at_v1';

  final SharedPreferences _prefs;

  static Future<SettingsStore> load() async {
    final s = SettingsStore(await SharedPreferences.getInstance());
    if (s._prefs.getString(_installedAtPref) == null) {
      await s._prefs.setString(_installedAtPref, DateTime.now().toIso8601String());
    }
    return s;
  }

  /// 첫 실행 시각. 30일 배너 기준.
  DateTime get installedAt => DateTime.tryParse(_prefs.getString(_installedAtPref) ?? '') ?? DateTime.now();
  int get daysSinceInstall => DateTime.now().difference(installedAt).inDays;

  bool get onboarded => _prefs.getBool(_onboardedPref) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_onboardedPref, value);

  /// 토요일 11:00 퀴즈 알림. 기본 켜짐.
  bool get quizReminder => _prefs.getBool(_quizReminderPref) ?? true;

  Future<void> setQuizReminder(bool value) => _prefs.setBool(_quizReminderPref, value);
}
