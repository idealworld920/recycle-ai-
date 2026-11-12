import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장소. 온보딩·동의·알림 설정·안내 표시 여부.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  /// 온보딩 완료 여부. 예전 키(onboarded_v1)도 읽는다.
  static const onboardingDonePref = 'onboardingDone';
  static const _legacyOnboardedPref = 'onboarded_v1';
  static const firstCameraHintPref = 'firstCameraHintShown';
  static const _consentPendingPref = 'consent_remote_pending';
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
  bool get onboarded => _prefs.getBool(onboardingDonePref) ?? _prefs.getBool(_legacyOnboardedPref) ?? false;

  Future<void> setOnboarded(bool value) async {
    await _prefs.setBool(onboardingDonePref, value);
    notifyListeners();
  }

  /// 온보딩 직후 카메라 화면의 리뿅이 말풍선. 첫 1회만.
  bool get firstCameraHintShown => _prefs.getBool(firstCameraHintPref) ?? false;
  Future<void> markFirstCameraHintShown() => _prefs.setBool(firstCameraHintPref, true);

  // ---- 동의 ----
  /// 기기에 저장하고, 서버(users/{uid}.consent) 기록은 보류 상태로 둔다.
  /// 익명 로그인이 끝나면 [consentDoc] 을 올리고 [markConsentSynced] 로 지운다.
  Future<void> saveConsent({required bool terms, required bool privacy, required bool marketing, required String version}) async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString('${_consentPrefix}terms', terms ? now : '');
    await _prefs.setString('${_consentPrefix}privacy', privacy ? now : '');
    await _prefs.setBool('${_consentPrefix}marketing', marketing);
    await _prefs.setString('${_consentPrefix}version', version);
    await _prefs.setBool(_consentPendingPref, true);
    notifyListeners();
  }

  bool get consentedRequired =>
      (_prefs.getString('${_consentPrefix}terms') ?? '').isNotEmpty && (_prefs.getString('${_consentPrefix}privacy') ?? '').isNotEmpty;
  String? get consentVersion => _prefs.getString('${_consentPrefix}version');
  bool get consentedMarketing => _prefs.getBool('${_consentPrefix}marketing') ?? false;

  /// 아직 서버에 못 올린 동의가 있는가.
  bool get consentRemotePending => (_prefs.getBool(_consentPendingPref) ?? false) && consentedRequired;
  Future<void> markConsentSynced() => _prefs.setBool(_consentPendingPref, false);

  /// users/{uid}.consent 에 올릴 값.
  Map<String, dynamic> get consentDoc => {
        'terms': _prefs.getString('${_consentPrefix}terms'),
        'privacy': _prefs.getString('${_consentPrefix}privacy'),
        'marketing': consentedMarketing,
        'version': consentVersion,
      };

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
