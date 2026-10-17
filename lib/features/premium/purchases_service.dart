import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchase_errors.dart';

/// RevenueCat 설정값. 키는 공개 키라 코드에 둬도 되지만, 빌드마다 바꾸기 쉽게 dart-define 으로 받는다.
class PremiumConfig {
  PremiumConfig._();

  static const androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// 개발 중 결제 없이 프리미엄 화면을 보려면 `--dart-define=PREMIUM_DEBUG=true`.
  static const debugPremium = bool.fromEnvironment('PREMIUM_DEBUG');

  static const entitlementId = 'premium';
  static const monthlyProductId = 'resai_premium_monthly';
  static const yearlyProductId = 'resai_premium_yearly';

  static String get apiKey => defaultTargetPlatform == TargetPlatform.iOS ? iosKey : androidKey;
  static bool get hasKey => !kIsWeb && apiKey.isNotEmpty;
}

/// purchases_flutter 래퍼. 키가 없거나 웹이면 "사용 불가" 모드로 조용히 동작한다.
class PurchasesService {
  PurchasesService._();

  static final PurchasesService instance = PurchasesService._();

  bool _configured = false;
  String? _appUserId;
  final _controller = StreamController<CustomerInfo>.broadcast();

  bool get available => PremiumConfig.hasKey;
  bool get configured => _configured;
  Stream<CustomerInfo> get customerInfoStream => _controller.stream;

  /// 익명 uid 를 appUserID 로 쓴다. 구글 연결로 uid 가 바뀌면 [logIn] 으로 alias.
  Future<void> configure(String appUserId) async {
    if (!available || _configured) return;
    try {
      await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(PremiumConfig.apiKey)..appUserID = appUserId);
      Purchases.addCustomerInfoUpdateListener(_controller.add);
      _appUserId = appUserId;
      _configured = true;
    } catch (e) {
      debugPrint('RevenueCat 설정 실패: $e');
    }
  }

  Future<void> logIn(String appUserId) async {
    if (!_configured || appUserId == _appUserId) return;
    try {
      final r = await Purchases.logIn(appUserId);
      _appUserId = appUserId;
      _controller.add(r.customerInfo);
    } catch (e) {
      debugPrint('RevenueCat logIn 실패: $e');
    }
  }

  Future<CustomerInfo?> customerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  Future<Offering?> currentOffering() async {
    if (!_configured) return null;
    try {
      return (await Purchases.getOfferings()).current;
    } catch (e) {
      debugPrint('offerings 실패: $e');
      return null;
    }
  }

  Future<PurchaseOutcome> purchase(Package package) async {
    if (!_configured) return const PurchaseFailed('결제 설정이 아직 안 됐어요. 곧 준비할게요.');
    try {
      final r = await Purchases.purchase(PurchaseParams.package(package));
      _controller.add(r.customerInfo);
      return const PurchaseSuccess();
    } catch (e) {
      return PurchaseErrors.outcomeOf(e);
    }
  }

  Future<PurchaseOutcome> restore() async {
    if (!_configured) return const PurchaseFailed('결제 설정이 아직 안 됐어요.');
    try {
      final info = await Purchases.restorePurchases();
      _controller.add(info);
      return info.entitlements.active.containsKey(PremiumConfig.entitlementId)
          ? const PurchaseSuccess()
          : const PurchaseFailed('복원할 구독이 없어요. 같은 Google 계정으로 로그인돼 있는지 확인해 주세요.');
    } catch (e) {
      return PurchaseErrors.outcomeOf(e);
    }
  }

  static bool hasPremium(CustomerInfo? info) => info?.entitlements.active.containsKey(PremiumConfig.entitlementId) ?? false;
}
