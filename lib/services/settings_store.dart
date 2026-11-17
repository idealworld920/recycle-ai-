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
  static const _lastOpenedPref = 'last_opened_at';
  static const _prevOpenedPref = 'prev_opened_at';
  static const _guideDismissedPref = 'guide_dismissed';
  static const _firstClassifyPref = 'firstClassifyDone';
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

  // ---- 리뿅이 ----
  /// 앱을 켤 때 한 번. 직전 실행 시각은 [previousOpenedAt] 으로 남겨 "3일 미접속 복귀" 판단에 쓴다.
  Future<void> markOpened() async {
    final last = _prefs.getInt(_lastOpenedPref);
    if (last != null) await _prefs.setInt(_prevOpenedPref, last);
    await _prefs.setInt(_lastOpenedPref, DateTime.now().millisecondsSinceEpoch);
  }

  /// 마지막으로 앱을 켠 시각 (이번 실행에서 [markOpened] 하기 전 값 = 직전 실행).
  DateTime? get lastOpenedAt {
    final ms = _prefs.getInt(_lastOpenedPref);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 스플래시 공지(Remote Config splash_message)에서 이미 본 id.
  static const _seenSplashPref = 'seen_splash_ids';
  Set<String> get seenSplashIds => (_prefs.getStringList(_seenSplashPref) ?? const []).toSet();
  Future<void> markSplashSeen(String id, {Future<void> Function(Map<String, dynamic>)? remote}) async {
    await _prefs.setStringList(_seenSplashPref, {...seenSplashIds, id}.toList());
    if (remote != null) {
      try {
        await remote({'seenSplash': {id: DateTime.now().toIso8601String()}});
      } catch (_) {}
    }
  }

  DateTime? get previousOpenedAt {
    final ms = _prefs.getInt(_prevOpenedPref);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 7일 가이드에서 닫은 항목.
  Set<String> get guideDismissed => (_prefs.getStringList(_guideDismissedPref) ?? const []).toSet();

  Future<void> dismissGuide(String key, {Future<void> Function(Map<String, dynamic>)? remote}) async {
    final next = {...guideDismissed, key};
    await _prefs.setStringList(_guideDismissedPref, next.toList());
    notifyListeners();
    if (remote != null) {
      try {
        await remote({
          'guide': {'installedAt': installedAt.toIso8601String(), 'dismissed': next.toList()},
        });
      } catch (_) {}
    }
  }

  /// 첫 분류 성공 축하는 1회.
  bool get firstClassifyDone => _prefs.getBool(_firstClassifyPref) ?? false;

  Future<void> markFirstClassifyDone({Future<void> Function(Map<String, dynamic>)? remote}) async {
    await _prefs.setBool(_firstClassifyPref, true);
    if (remote != null) {
      try {
        await remote({'firstClassifyDone': true});
      } catch (_) {}
    }
  }

  // ---- 설치일 ----
  DateTime get installedAt => DateTime.tryParse(_prefs.getString(_installedAtPref) ?? '') ?? DateTime.now();
  int get daysSinceInstall => DateTime.now().difference(installedAt).inDays;

  /// 설치 후 72시간은 무료 한도(분류 10회·질문 5회)를 적용하지 않는다.
  static const freeGrace = Duration(hours: 72);
  bool get inFreeGrace => DateTime.now().difference(installedAt) < freeGrace;

  /// 내 데이터 삭제 시: 온보딩·동의·안내 플래그를 지워 처음 상태로.
  // ---- 분석·리뷰용 카운터 ----
  static const _counterPrefix = 'counter_';
  static const _reviewPromptPref = 'review_prompt_at';
  static const _bubbleLoggedPref = 'ribbong_bubble_logged_day';

  int counter(String key) => _prefs.getInt('$_counterPrefix$key') ?? 0;

  /// 1 올리고 새 값을 돌려준다.
  Future<int> bump(String key) async {
    final v = counter(key) + 1;
    await _prefs.setInt('$_counterPrefix$key', v);
    return v;
  }

  DateTime? get reviewPromptAt => DateTime.tryParse(_prefs.getString(_reviewPromptPref) ?? '');

  Future<void> markReviewPrompted({Future<void> Function(Map<String, dynamic>)? remote}) async {
    final now = DateTime.now();
    await _prefs.setString(_reviewPromptPref, now.toIso8601String());
    if (remote != null) {
      try {
        await remote({'reviewPromptAt': now.toIso8601String()});
      } catch (_) {}
    }
  }

  /// 홈 말풍선 노출 이벤트는 하루 1회만. 오늘 처음이면 true 를 돌려주고 기록한다.
  Future<bool> claimDailyBubbleLog(DateTime now) async {
    final key = '${now.year}-${now.month}-${now.day}';
    if (_prefs.getString(_bubbleLoggedPref) == key) return false;
    await _prefs.setString(_bubbleLoggedPref, key);
    return true;
  }

  // ---- 오랜만 인사 알림 (평생 1회) ----
  static const _comebackSentPref = 'comeback_nudge_sent_at';
  static const _comebackScheduledPref = 'comeback_nudge_scheduled_at';
  bool get comebackSent => _prefs.containsKey(_comebackSentPref);
  DateTime? get comebackScheduledAt => DateTime.tryParse(_prefs.getString(_comebackScheduledPref) ?? '');
  Future<void> setComebackScheduled(DateTime? at) => at == null ? _prefs.remove(_comebackScheduledPref) : _prefs.setString(_comebackScheduledPref, at.toIso8601String());
  Future<void> markComebackSent({Future<void> Function(Map<String, dynamic>)? remote}) async {
    final now = DateTime.now();
    await _prefs.setString(_comebackSentPref, now.toIso8601String());
    await _prefs.remove(_comebackScheduledPref);
    if (remote != null) {
      try {
        await remote({'comebackNudgeSentAt': now.toIso8601String()});
      } catch (_) {}
    }
  }

  Future<void> resetAll() async {
    for (final k in _prefs.getKeys().toList()) {
      await _prefs.remove(k);
    }
    await _prefs.setString(_installedAtPref, DateTime.now().toIso8601String());
  }

  void notifyReset() => notifyListeners();
}
