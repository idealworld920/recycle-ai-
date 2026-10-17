import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장소. 온보딩·동의·알림 설정·안내 표시 여부.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  static const _onboardedPref = 'onboarded_v1';
  static const _installedAtPref = 'installed_at_v1';
  static const _consentPrefix = 'consent_';
  static const _primerPrefix = 'primer_shown_';

  final SharedPreferences _prefs;

  static Future<SettingsStore> load() async {
    final s = SettingsStore(await SharedPreferences.getInstance());
    if (s._prefs.getString(_installedAtPref) == null) {
      await s._prefs.setString(_installedAtPref, DateTime.now().toIso8601String());
    }
    return s;
  }

  // ---- 온보딩 ----
  bool get onboarded => _prefs.getBool(_onboardedPref) ?? false;

  Future<void> setOnboarded(bool value) async {
    await _prefs.setBool(_onboardedPref, value);
    notifyListeners();
  }

  // ---- 동의 ----
  Future<void> saveConsent({required bool terms, required bool privacy, required bool notifications, required String version}) async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString('${_consentPrefix}terms', terms ? now : '');
    await _prefs.setString('${_consentPrefix}privacy', privacy ? now : '');
    await _prefs.setBool('${_consentPrefix}notifications', notifications);
    await _prefs.setString('${_consentPrefix}version', version);
    notifyListeners();
  }

  bool get consentedRequired =>
      (_prefs.getString('${_consentPrefix}terms') ?? '').isNotEmpty && (_prefs.getString('${_consentPrefix}privacy') ?? '').isNotEmpty;
  String? get consentVersion => _prefs.getString('${_consentPrefix}version');
  bool get consentedNotifications => _prefs.getBool('${_consentPrefix}notifications') ?? false;

  // ---- 권한 사전 안내 ----
  bool primerShown(String kind) => _prefs.getBool('$_primerPrefix$kind') ?? false;
  Future<void> markPrimerShown(String kind) => _prefs.setBool('$_primerPrefix$kind', true);

  // ---- 설치일 ----
  DateTime get installedAt => DateTime.tryParse(_prefs.getString(_installedAtPref) ?? '') ?? DateTime.now();
  int get daysSinceInstall => DateTime.now().difference(installedAt).inDays;

  /// 내 데이터 삭제 시: 온보딩·동의·안내 플래그를 지워 처음 상태로.
  Future<void> resetAll() async {
    for (final k in _prefs.getKeys().toList()) {
      await _prefs.remove(k);
    }
    await _prefs.setString(_installedAtPref, DateTime.now().toIso8601String());
  }

  void notifyReset() => notifyListeners();
}
