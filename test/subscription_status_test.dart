import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/premium/subscription_status.dart';

void main() {
  final exp = DateTime(2026, 12, 15, 9).toUtc().toIso8601String();

  test('갱신 예정: "ReSAI 프리미엄 사용 중 · 12월 15일 갱신"', () {
    final s = SubscriptionStatus.from(active: true, willRenew: true, periodType: 'normal', expiresAt: exp, productId: 'resai_premium_monthly:monthly');
    expect(s.phase, SubscriptionPhase.active);
    expect(s.headline(priceString: '₩2,900'), 'ReSAI 프리미엄 사용 중 · 12월 15일 갱신');
  });

  test('체험 중: "7일 무료 체험 중 · 11월 22일부터 월 ₩2,900" (가격 없으면 숫자 없이)', () {
    final e = DateTime(2026, 11, 22, 9).toUtc().toIso8601String();
    final s = SubscriptionStatus.from(active: true, willRenew: true, periodType: 'trial', expiresAt: e, productId: 'resai_premium_monthly:monthly');
    expect(s.phase, SubscriptionPhase.trial);
    expect(s.headline(priceString: '₩2,900'), '7일 무료 체험 중 · 11월 22일부터 월 ₩2,900');
    expect(s.headline(), '7일 무료 체험 중 · 11월 22일부터 자동 갱신');
    final y = SubscriptionStatus.from(active: true, willRenew: true, periodType: 'intro', expiresAt: e, productId: 'resai_premium_yearly:yearly');
    expect(y.isYearly, isTrue);
    expect(y.headline(priceString: '₩19,900'), '7일 무료 체험 중 · 11월 22일부터 연 ₩19,900');
  });

  test('해지 예정: "프리미엄 · 12월 15일까지 이용 가능 (해지 예정)" — 체험 중이어도 willRenew=false 가 우선', () {
    final s = SubscriptionStatus.from(active: true, willRenew: false, periodType: 'trial', expiresAt: exp, productId: 'resai_premium_yearly');
    expect(s.phase, SubscriptionPhase.cancelled);
    expect(s.headline(priceString: '₩19,900'), '프리미엄 · 12월 15일까지 이용 가능 (해지 예정)');
  });

  test('만료/없음 → none, 제목은 플랜 이름', () {
    final s = SubscriptionStatus.from(active: false, willRenew: false, periodType: 'normal', expiresAt: exp);
    expect(s.phase, SubscriptionPhase.none);
    expect(s.isActive, isFalse);
    expect(s.headline(), 'ReSAI 프리미엄');
  });

  test('만료일 파싱 실패 시에도 문구는 깨지지 않는다', () {
    final s = SubscriptionStatus.from(active: true, willRenew: true, periodType: 'normal', expiresAt: 'garbage');
    expect(s.headline(), 'ReSAI 프리미엄 사용 중');
  });
}
