import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/paywall/paywall_trigger.dart';
import 'package:recycle_ai/features/premium/premium_gate.dart';
import 'package:recycle_ai/features/premium/price_format.dart';
import 'package:recycle_ai/features/premium/trial_reminders.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 17, 12);
  final installedLongAgo = now.subtract(const Duration(days: 10));

  Future<PaywallTrigger> trigger({DateTime? at}) async {
    return PaywallTrigger(await SharedPreferences.getInstance(), now: () => at ?? now);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('가격 환산 (스토어 가격으로만)', () {
    test('연간 19,900원 → 월 1,658원 · 하루 55원 / 월간 2,900원 → 하루 97원', () {
      expect(PriceFormat.yearlyEquivalent(19900, 'KRW'), '월 1,658원 · 하루 55원');
      expect(PriceFormat.monthlyEquivalent(2900, 'KRW'), '하루 97원');
      expect(PriceFormat.money(1234567, 'KRW'), '1,234,567원');
      expect(PriceFormat.money(1.99, 'USD'), r'$1.99');
      expect(PriceFormat.money(3.5, 'EUR'), 'EUR 3.50');
    });
  });

  group('거절 존중 (7일 쿨다운)', () {
    test('페이월을 닫으면 자동 노출은 7일 쉬고, 설정·막힘 화면 버튼·잠긴 기능 탭은 유지', () async {
      final t = await trigger();
      Map<String, dynamic>? sent;
      await t.markDismissed(remote: (m) async => sent = m);
      expect(sent!['paywallDismissedAt'], isA<String>());
      expect(t.inDismissCooldown, isTrue);
      bool can(PaywallSource s, {bool user = false}) => t.canShow(s, installedAt: installedLongAgo, onboarded: true, userInitiated: user);
      // 자동(A·D)
      expect(can(PaywallSource.limitWarning, user: true), isFalse);
      expect(can(PaywallSource.scheduleDone, user: true), isFalse);
      expect(can(PaywallSource.collection10, user: true), isFalse);
      expect(can(PaywallSource.streak3), isFalse);
      expect(can(PaywallSource.reportBottom), isFalse);
      // 유지
      expect(can(PaywallSource.settings), isTrue);
      expect(can(PaywallSource.limitBlock), isTrue);
      expect(can(PaywallSource.chatLimitBlock), isTrue);
      expect(can(PaywallSource.household, user: true), isTrue);
      expect(can(PaywallSource.guide7, user: true), isTrue);
      // 8일 뒤엔 풀린다
      final later = await trigger(at: now.add(const Duration(days: 8)));
      expect(later.inDismissCooldown, isFalse);
      expect(later.canShow(PaywallSource.limitWarning, installedAt: installedLongAgo, onboarded: true, userInitiated: true), isTrue);
    });
  });

  group('소프트 진입 (평생 1회 · 72시간 · 쿨다운)', () {
    test('조건이 맞으면 한 번만, 설치 72시간 안엔 안 됨', () async {
      final t = await trigger();
      expect(t.canShowSoft(PaywallSource.scheduleDone, installedAt: now.subtract(const Duration(hours: 71)), onboarded: true), isFalse);
      expect(t.canShowSoft(PaywallSource.scheduleDone, installedAt: installedLongAgo, onboarded: false), isFalse);
      expect(t.canShowSoft(PaywallSource.scheduleDone, installedAt: installedLongAgo, onboarded: true), isTrue);
      await t.markSoftShown(PaywallSource.scheduleDone);
      expect(t.canShowSoft(PaywallSource.scheduleDone, installedAt: installedLongAgo, onboarded: true), isFalse);
      // 다른 소프트는 독립
      expect(t.canShowSoft(PaywallSource.collection10, installedAt: installedLongAgo, onboarded: true), isTrue);
      expect(t.canShowSoft(PaywallSource.streak3, installedAt: installedLongAgo, onboarded: true), isTrue);
      // 소프트가 아닌 source 는 false
      expect(t.canShowSoft(PaywallSource.settings, installedAt: installedLongAgo, onboarded: true), isFalse);
      // 거절 쿨다운이면 소프트도 쉼
      await t.markDismissed();
      expect(t.canShowSoft(PaywallSource.collection10, installedAt: installedLongAgo, onboarded: true), isFalse);
    });
  });

  group('분석 source 이름', () {
    test('새 진입점 이름', () {
      expect(PaywallSource.limitWarning.analyticsName, 'limit_warning');
      expect(PaywallSource.limitBlock.analyticsName, 'limit_block');
      expect(PaywallSource.chatLimitBlock.analyticsName, 'chat_limit_block');
      expect(PaywallSource.scheduleDone.analyticsName, 'schedule_done');
      expect(PaywallSource.collection10.analyticsName, 'collection_10');
      expect(PaywallSource.streak3.analyticsName, 'streak3');
      expect(PaywallSource.limitBlock.isUserButton, isTrue);
      expect(PaywallSource.scheduleDone.isSoft, isTrue);
    });
  });

  group('체험 종료 알림 시각', () {
    test('시작 +5일 20:00, +6일 20:00', () {
      final times = TrialReminders.timesFor(DateTime(2026, 11, 17, 9, 30));
      expect(times, [DateTime(2026, 11, 22, 20), DateTime(2026, 11, 23, 20)]);
      // 월말 넘어가도 DateTime 이 정규화한다
      expect(TrialReminders.timesFor(DateTime(2026, 11, 28)), [DateTime(2026, 12, 3, 20), DateTime(2026, 12, 4, 20)]);
    });
  });
}
