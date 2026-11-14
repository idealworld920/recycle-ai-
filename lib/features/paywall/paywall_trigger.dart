import 'package:shared_preferences/shared_preferences.dart';

import '../premium/premium_gate.dart' show PaywallSource;

/// 페이월을 언제 띄울지. 자동 노출(reportBottom·streak3·share3)은 평생 1회, limitHit 는 하루 1회,
/// featureTap 은 사용자가 잠긴 기능을 눌렀을 때. 설치 72시간 안·첫 제한 도달 전·온보딩 중엔 띄우지 않는다.
/// 노출 기록은 기기(prefs)와 users/{uid}.paywallShown 에 같이 남긴다.
class PaywallTrigger {
  PaywallTrigger(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const minInstallAge = Duration(hours: 72);
  static const shownPrefix = 'paywall_shown_';
  static const localShareCountPref = 'paywall_share_count';
  static const firstLimitPref = 'paywall_first_limit_hit';

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

  /// 지금 이 계기로 페이월을 띄워도 되는가.
  bool canShow(PaywallSource source, {required DateTime installedAt, required bool onboarded, bool userInitiated = false}) {
    if (source == PaywallSource.settings) return true;
    if (!onboarded) return false;
    if (_now().difference(installedAt) < minInstallAge) return false;
    // 사용자가 직접 누른 CTA 는 "평생 1회" 제한을 받지 않는다 (72시간·온보딩 가드만).
    if (userInitiated && source != PaywallSource.limitHit) return true;
    final last = lastShown(source);
    switch (source) {
      case PaywallSource.featureTap:
      case PaywallSource.guide7:
        return true;
      case PaywallSource.limitHit:
        return last == null || !_sameDay(last, _now());
      case PaywallSource.reportBottom:
      case PaywallSource.streak3:
      case PaywallSource.share3:
        return limitHitOnce && last == null;
      case PaywallSource.settings:
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
