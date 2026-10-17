import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장소. 지금은 Gemini API 키만 다룬다.
///
/// 빌드 시 `--dart-define=GEMINI_API_KEY=...`로 기본 키를 넣을 수 있고,
/// 설정 화면에서 입력한 키가 있으면 그 키를 우선 사용한다.
class SettingsStore {
  SettingsStore(this._prefs);

  static const _apiKeyPref = 'gemini_api_key';
  static const _buildTimeKey = String.fromEnvironment('GEMINI_API_KEY');

  final SharedPreferences _prefs;

  static Future<SettingsStore> load() async {
    return SettingsStore(await SharedPreferences.getInstance());
  }

  String get apiKey {
    final saved = _prefs.getString(_apiKeyPref)?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return _buildTimeKey;
  }

  bool get hasApiKey => apiKey.isNotEmpty;

  bool get isUsingBuildTimeKey =>
      (_prefs.getString(_apiKeyPref)?.trim().isEmpty ?? true) &&
      _buildTimeKey.isNotEmpty;

  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_apiKeyPref);
    } else {
      await _prefs.setString(_apiKeyPref, trimmed);
    }
  }
}
