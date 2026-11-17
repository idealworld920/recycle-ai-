import 'package:shared_preferences/shared_preferences.dart';

import '../premium/premium_gate.dart' show PaywallSource;

/// 페이월을 언제 띄울지. 자동 노출(reportBottom·streak3·share3)은 평생 1회, limitHit 는 하루 1회,
/// featureTap 은 사용자가 잠긴 기능을 눌렀을 때. 설치 72시간 안·첫 제한 도달 전·온보딩 중엔 띄우지 않는다.
/// 노출 기록은 기기(prefs)와 users/{uid}.paywallShown 에 같이 남긴다.
class PaywallTrigger {
  PaywallTrigger(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const minInstallAge = Duration(hours: 72);
  static const dismissCooldown = Duration(days: 7);
  static const shownPrefix = 'paywall_shown_';
  static const softPrefix = 'paywall_soft_';
  static const localShareCountPref = 'paywall_share_count';
  static const firstLimitPref = 'paywall_first_limit_hit';
  static const dismissedPref = 'paywall_dismissed_at';

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  /// 제한에 처음 닿았을 때 한 번 기록. 자동 노출의 선행 조건.
  Future<void> markLimitHit() async {
    if (!_prefs.containsKey(firstLimitPref)) await _prefs.setInt(firstLimitPref, _now().millisecondsSinceEpoch);
  }

  bool get limitHitOnce => _prefs.containsKey(firstLimitPref);

  DateTime? lastShown(PaywallSource s) {
    final ms = _prefs.getInt('$shownPrefix${s.name}');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 사용자가 페이월을 닫은 시각. 7일 동안은 자동(A·D) 노출을 쉰다.
  DateTime? get dismissedAt {
    final ms = _prefs.getInt(dismissedPref);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get inDismissCooldown {
    final d = dismissedAt;
    return d != null && _now().difference(d) < dismissCooldown;
  }

  /// 페이월을 결제 없이 닫았을 때. users/{uid}.paywallDismissedAt 에도 남긴다.
  Future<void> markDismissed({Future<void> Function(Map<String, dynamic>)? remote}) async {
    final t = _now();
    await _prefs.setInt(dismissedPref, t.millisecondsSinceEpoch);
    if (remote != null) {
      try {
        await remote({'paywallDismissedAt': t.toIso8601String()});
      } catch (_) {}
    }
  }

  bool pastInstallAge(DateTime installedAt) => _now().difference(installedAt) >= minInstallAge;

  /// 소프트 진입(수거일 설정 직후·도감 10개·3주 연속)은 평생 1회.
  bool softShown(PaywallSource s) => _prefs.containsKey('$softPrefix${s.name}');
  Future<void> markSoftShown(PaywallSource s) => _prefs.setInt('$softPrefix${s.name}', _now().millisecondsSinceEpoch);

  /// 소프트 시트를 띄워도 되는가: 온보딩 끝 + 72시간 지남 + 거절 쿨다운 아님 + 아직 안 보여줌.
  bool canShowSoft(PaywallSource s, {required DateTime installedAt, required bool onboarded}) =>
      s.isSoft && onboarded && pastInstallAge(installedAt) && !inDismissCooldown && !softShown(s);

  /// 지금 이 계기로 페이월을 띄워도 되는가.
  bool canShow(PaywallSource source, {required DateTime installedAt, required bool onboarded, bool userInitiated = false}) {
    if (source.isUserButton) return true;
    if (!onboarded) return false;
    if (!pastInstallAge(installedAt)) return false;
    // 거절 뒤 7일: 자동 노출(A·D)은 쉰다. 잠긴 기능을 직접 누른 경우(featureTap 계열·guide7)는 그대로.
    if (inDismissCooldown && !source.isFeatureTap && source != PaywallSource.guide7) return false;
    // 사용자가 직접 누른 CTA 는 "평생 1회" 제한을 받지 않는다 (72시간·온보딩 가드만).
    if (userInitiated && source != PaywallSource.limitHit) return true;
    final last = lastShown(source);
    switch (source) {
      case PaywallSource.featureTap:
      case PaywallSource.household:
      case PaywallSource.calendar:
      case PaywallSource.multi:
      case PaywallSource.guide7:
      case PaywallSource.limitWarning:
        return true;
      case PaywallSource.limitHit:
        return last == null || !_sameDay(last, _now());
      case PaywallSource.reportBottom:
      case PaywallSource.share3:
        return limitHitOnce && last == null;
      case PaywallSource.streak3:
      case PaywallSource.scheduleDone:
      case PaywallSource.collection10:
        return last == null;
      case PaywallSource.settings:
      case PaywallSource.limitBlock:
      case PaywallSource.chatLimitBlock:
        return true;
    }
  }

  /// 띄웠으면 기록. 서버 기록은 호출자가 [remote] 로 넘긴다 (users/{uid}.paywallShown.{source}).
  Future<void> markShown(PaywallSource source, {Future<void> Function(Map<String, dynamic>)? remote}) async {
    final t = _now();
    await _prefs.setInt('$shownPrefix${source.name}', t.millisecondsSinceEpoch);
    if (remote != null) {
      try {
        await remote({
          'paywallShown': {source.name: t.toIso8601String()},
        });
      } catch (_) {}
    }
  }

  /// 공유 성공 횟수(기기). 3회째에 true.
  Future<bool> countShare() async {
    final n = (_prefs.getInt(localShareCountPref) ?? 0) + 1;
    await _prefs.setInt(localShareCountPref, n);
    return n == 3;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
