import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/paywall/paywall_trigger.dart';
import 'package:recycle_ai/features/premium/premium_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  final installed = DateTime(2026, 11, 1, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PaywallTrigger at(DateTime now) => PaywallTrigger(prefs, now: () => now);

  test('설치 72시간 안·온보딩 중엔 어떤 계기로도 안 띄운다 (설정·막힘 화면 버튼 제외)', () {
    final t = at(installed.add(const Duration(hours: 71)));
    for (final s in PaywallSource.values.where((s) => !s.isUserButton)) {
      expect(t.canShow(s, installedAt: installed, onboarded: true), isFalse, reason: s.name);
    }
    expect(t.canShow(PaywallSource.settings, installedAt: installed, onboarded: true), isTrue);
    final later = at(installed.add(const Duration(days: 5)));
    expect(later.canShow(PaywallSource.featureTap, installedAt: installed, onboarded: false), isFalse);
  });

  test('featureTap 은 72시간 뒤면 매번, limitHit 는 하루 1회', () async {
    final day5 = installed.add(const Duration(days: 5));
    final t = at(day5);
    expect(t.canShow(PaywallSource.featureTap, installedAt: installed, onboarded: true), isTrue);
    await t.markShown(PaywallSource.featureTap);
    expect(t.canShow(PaywallSource.featureTap, installedAt: installed, onboarded: true), isTrue);

    expect(t.canShow(PaywallSource.limitHit, installedAt: installed, onboarded: true), isTrue);
    await t.markShown(PaywallSource.limitHit);
    expect(t.canShow(PaywallSource.limitHit, installedAt: installed, onboarded: true), isFalse);
    expect(at(day5.add(const Duration(days: 1))).canShow(PaywallSource.limitHit, installedAt: installed, onboarded: true), isTrue);
  });

  test('자동 노출(reportBottom·share3)은 첫 제한 도달 뒤 평생 1회, streak3 는 소프트 시트가 1회를 관리한다', () async {
    final t = at(installed.add(const Duration(days: 10)));
    expect(t.canShow(PaywallSource.share3, installedAt: installed, onboarded: true), isFalse); // 아직 제한 전
    await t.markLimitHit();
    expect(t.canShow(PaywallSource.share3, installedAt: installed, onboarded: true), isTrue);
    await t.markShown(PaywallSource.share3);
    expect(t.canShow(PaywallSource.share3, installedAt: installed, onboarded: true), isFalse);
    expect(t.canShow(PaywallSource.streak3, installedAt: installed, onboarded: true), isTrue);
    await t.markShown(PaywallSource.streak3);
    expect(t.canShow(PaywallSource.streak3, installedAt: installed, onboarded: true), isFalse);
    // 사용자가 직접 누른 CTA 는 1회 제한을 받지 않는다
    expect(t.canShow(PaywallSource.reportBottom, installedAt: installed, onboarded: true, userInitiated: true), isTrue);
  });

  test('markShown 은 서버 기록 콜백에 paywallShown.{source} 를 넘긴다', () async {
    Map<String, dynamic>? sent;
    final t = at(installed.add(const Duration(days: 4)));
    await t.markShown(PaywallSource.share3, remote: (m) async => sent = m);
    expect((sent!['paywallShown'] as Map).containsKey('share3'), isTrue);
    expect(t.lastShown(PaywallSource.share3), isNotNull);
  });

  test('공유 3회째에 true', () async {
    final t = at(installed);
    expect(await t.countShare(), isFalse);
    expect(await t.countShare(), isFalse);
    expect(await t.countShare(), isTrue);
    expect(await t.countShare(), isFalse);
  });
}
