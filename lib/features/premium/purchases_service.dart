import 'package:flutter/foundation.dart';

import 'purchase_errors.dart';

/// 프리미엄 설정값.
///
/// 1.1.0 에는 구독(결제)이 없다. RevenueCat(purchases_flutter)은 1.4.0 에서 다시 붙인다 — README "구독 (RevenueCat) 설정" 참고.
/// 그동안 프리미엄은 `PREMIUM_DEBUG` 또는 검토자 코드(`REVIEW_CODE`)로만 열린다.
class PremiumConfig {
  PremiumConfig._();

  static const androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// 개발 중 결제 없이 프리미엄 화면을 보려면 `--dart-define=PREMIUM_DEBUG=true`.
  static const debugPremium = bool.fromEnvironment('PREMIUM_DEBUG');

  /// Play 검토자용. `--dart-define=REVIEW_CODE=...` 로 넣은 코드를 설정 → 앱 정보 7번 탭 → 입력하면
  /// 결제 없이 30일 동안 프리미엄이 열린다. 비어 있으면 기능 자체가 꺼진다. 코드는 저장소에 두지 않는다.
  static const reviewCode = String.fromEnvironment('REVIEW_CODE');
  static const reviewDays = 30;

  static const entitlementId = 'premium';
  static const monthlyProductId = 'resai_premium_monthly';
  static const yearlyProductId = 'resai_premium_yearly';

  /// 이 버전에 예정된 구독 출시 안내 문구.
  static const comingSoon = '프리미엄 구독은 다음 업데이트에서 열려요. 지금은 모든 기능을 무료 한도 안에서 쓸 수 있어요.';

  static String get apiKey => defaultTargetPlatform == TargetPlatform.iOS ? iosKey : androidKey;

  /// 결제 SDK 가 빠져 있어 항상 false. (키가 있어도 켜지지 않는다)
  static bool get hasKey => false;
}

/// 결제 서비스 자리. 1.1.0 에서는 아무것도 하지 않는다.
///
/// 1.4.0 에서 purchases_flutter 를 다시 넣을 때 이 클래스를 SDK 래퍼로 되돌린다
/// (git 기록의 "Strip purchases_flutter" 이전 버전 참고).
class PurchasesService {
  PurchasesService._();

  static final PurchasesService instance = PurchasesService._();

  bool get available => false;
  bool get configured => false;

  Future<void> configure(String appUserId) async {}

  Future<void> logIn(String appUserId) async {}

  Future<PurchaseOutcome> purchase() async => const PurchaseFailed(PremiumConfig.comingSoon);

  Future<PurchaseOutcome> restore() async => const PurchaseFailed(PremiumConfig.comingSoon);
}
