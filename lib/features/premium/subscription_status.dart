import 'purchases_service.dart';

/// RevenueCat entitlement 를 설정 카드용 상태로 정리한 값. 순수 Dart (테스트 가능).
enum SubscriptionPhase {
  /// 구독 없음(또는 만료).
  none,

  /// 무료 체험 중 (periodType == trial / intro).
  trial,

  /// 유료 구독 중, 갱신 예정.
  active,

  /// 해지 예정: 만료일까지 이용 가능, 갱신 안 함.
  cancelled,
}

class SubscriptionStatus {
  const SubscriptionStatus({required this.phase, this.expiresAt, this.productId});

  static const none = SubscriptionStatus(phase: SubscriptionPhase.none);

  final SubscriptionPhase phase;
  final DateTime? expiresAt;
  final String? productId;

  bool get isActive => phase != SubscriptionPhase.none;
  bool get isYearly => productId?.startsWith(PremiumConfig.yearlyProductId) ?? false;

  /// "월" / "연".
  String get periodLabel => isYearly ? '연' : '월';

  /// RevenueCat EntitlementInfo 값으로 만든다. [active] 가 false 면 none.
  factory SubscriptionStatus.from({
    required bool active,
    required bool willRenew,
    required String periodType, // 'trial' | 'intro' | 'normal' | 'unknown'
    String? expiresAt,
    String? productId,
  }) {
    if (!active) return none;
    final exp = expiresAt == null ? null : DateTime.tryParse(expiresAt)?.toLocal();
    final phase = !willRenew
        ? SubscriptionPhase.cancelled
        : (periodType == 'trial' || periodType == 'intro')
            ? SubscriptionPhase.trial
            : SubscriptionPhase.active;
    return SubscriptionStatus(phase: phase, expiresAt: exp, productId: productId);
  }

  static String monthDay(DateTime d) => '${d.month}월 ${d.day}일';

  /// 설정 프리미엄 카드 제목 한 줄. [priceString] 은 스토어 가격(예: ₩2,900), 없으면 숫자 없는 문구.
  String headline({String? priceString}) {
    final day = expiresAt == null ? null : monthDay(expiresAt!);
    switch (phase) {
      case SubscriptionPhase.none:
        return PremiumConfig.planName;
      case SubscriptionPhase.active:
        return day == null ? '${PremiumConfig.planName} 사용 중' : '${PremiumConfig.planName} 사용 중 · $day 갱신';
      case SubscriptionPhase.trial:
        final after = priceString == null ? '자동 갱신' : '$periodLabel $priceString';
        return day == null ? '${PremiumConfig.trialDays}일 무료 체험 중' : '${PremiumConfig.trialDays}일 무료 체험 중 · $day부터 $after';
      case SubscriptionPhase.cancelled:
        return day == null ? '프리미엄 · 해지 예정' : '프리미엄 · $day까지 이용 가능 (해지 예정)';
    }
  }
}
