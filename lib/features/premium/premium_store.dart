import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../household/household_store.dart';
import 'purchase_errors.dart';
import 'purchases_service.dart';
import 'subscription_status.dart';

/// 프리미엄이 열리는 세 경로. 표시용.
enum PremiumSource { none, own, family, review, debug }

/// 프리미엄 상태.
///
/// 내 구독의 진실은 RevenueCat SDK(entitlement "premium"). 집 멤버는 방장 구독이 웹훅으로 적어 준
/// households/{id}.premiumUntil 로 판단한다. Firestore users/{uid}.premium 은 웹훅만 쓴다. 임시 true 는 없다.
class PremiumStore extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  PremiumStore(this._service, {SharedPreferences? prefs}) : _prefs = prefs {
    _reviewUntil = _prefs?.getInt(reviewPrefKey) ?? 0;
    _sub = _service.customerInfoStream.listen(_applyInfo);
  }

  static const reviewPrefKey = 'review_premium_until';

  final PurchasesService _service;
  final SharedPreferences? _prefs;
  HouseholdStore? _household;
  int _reviewUntil = 0;
  StreamSubscription<CustomerInfo>? _sub;
  bool _own = false;
  String? _expiresAt;
  String? _productId;
  SubscriptionStatus _status = SubscriptionStatus.none;
  Offering? _offering;
  bool _offeringLoading = false;
  bool _offeringTried = false;
  bool _busy = false;

  /// 집 방장 구독을 같이 본다.
  void attachHousehold(HouseholdStore household) {
    _household = household;
    household.addListener(notifyListeners);
  }

  bool get isPremium => source != PremiumSource.none;

  PremiumSource get source {
    if (PremiumConfig.debugPremium) return PremiumSource.debug;
    if (_own) return PremiumSource.own;
    if (_household?.familyPlanActive ?? false) return PremiumSource.family;
    if (reviewActive) return PremiumSource.review;
    return PremiumSource.none;
  }

  /// 내 구독(또는 집 플랜)의 다음 갱신/만료 시각.
  DateTime? get renewsAt {
    if (_own && _expiresAt != null) return DateTime.tryParse(_expiresAt!);
    if (_household?.familyPlanActive ?? false) return _household!.familyPlanUntil;
    if (reviewActive) return DateTime.fromMillisecondsSinceEpoch(_reviewUntil);
    return null;
  }

  /// 검토자 코드로 열린 임시 프리미엄.
  bool get reviewActive => _reviewUntil > DateTime.now().millisecondsSinceEpoch;

  /// 설정 → 앱 정보에서 입력한 코드. 맞으면 [PremiumConfig.reviewDays] 동안 열린다.
  Future<bool> tryReviewCode(String code) async {
    final expected = PremiumConfig.reviewCode.trim();
    if (expected.isEmpty || code.trim() != expected) return false;
    _reviewUntil = DateTime.now().add(const Duration(days: PremiumConfig.reviewDays)).millisecondsSinceEpoch;
    await _prefs?.setInt(reviewPrefKey, _reviewUntil);
    notifyListeners();
    return true;
  }

  bool get available => _service.available;
  bool get busy => _busy;
  String? get expiresAt => _expiresAt;
  String? get productId => _productId;
  Offering? get offering => _offering;

  /// 내 구독의 단계(체험/갱신 예정/해지 예정). 집 플랜·검토 모드는 none.
  SubscriptionStatus get status => _status;

  /// 가격을 불러오는 중인가 (한 번도 성공 못 했고 시도 중이거나 아직 시도 전).
  bool get pricesLoading => _offering == null && (_offeringLoading || !_offeringTried);
  bool get pricesFailed => _offering == null && _offeringTried && !_offeringLoading;

  /// 스토어 가격 문자열 (예: ₩2,900). 아직 없으면 null — 숫자를 지어내지 않는다.
  String? get monthlyPrice => monthly?.storeProduct.priceString;
  String? get yearlyPrice => yearly?.storeProduct.priceString;

  /// 연간이 월간×12 대비 몇 % 싼지. 둘 다 있어야 계산한다.
  int? get yearlyDiscountPercent {
    final m = monthly?.storeProduct.price;
    final y = yearly?.storeProduct.price;
    if (m == null || y == null || m <= 0) return null;
    final pct = ((1 - y / (m * 12)) * 100).round();
    return pct > 0 ? pct : null;
  }

  /// 선택 패키지에 무료 체험 자격이 있는가 (Play 오퍼 또는 introductoryPrice).
  static bool trialEligible(Package? p) => p != null && (trialOption(p) != null || p.storeProduct.introductoryPrice != null);

  Package? get monthly => _offering?.monthly ?? _find(PremiumConfig.monthlyProductId);
  Package? get yearly => _offering?.annual ?? _find(PremiumConfig.yearlyProductId);

  Package? _find(String productId) =>
      _offering?.availablePackages.where((p) => p.storeProduct.identifier.startsWith(productId)).firstOrNull;

  void _applyInfo(CustomerInfo info) {
    final e = PurchasesService.entitlement(info);
    _own = e != null;
    _expiresAt = e?.expirationDate;
    _productId = e?.productIdentifier;
    _status = e == null
        ? SubscriptionStatus.none
        : SubscriptionStatus.from(active: true, willRenew: e.willRenew, periodType: e.periodType.name, expiresAt: e.expirationDate, productId: e.productIdentifier);
    notifyListeners();
  }

  /// 포그라운드 복귀 등: 서버에서 구독 상태를 다시 읽어 만료·해지를 즉시 반영한다.
  Future<void> refresh() async {
    if (!_service.configured) return;
    final info = await _service.refreshCustomerInfo();
    if (info != null) _applyInfo(info);
  }

  /// uid 가 정해지면 호출. 처음엔 configure(익명 uid = appUserID), 이후엔 alias(logIn).
  Future<void> attachUser(String? uid) async {
    if (uid == null || !_service.available) return;
    if (!_service.configured) {
      await _service.configure(uid);
    } else {
      await _service.logIn(uid);
    }
    final info = await _service.customerInfo();
    if (info != null) _applyInfo(info);
    notifyListeners();
    // 가격은 설정 카드·페이월에서 바로 쓰이므로 미리 받아 둔다.
    if (_offering == null) unawaited(loadOffering());
  }

  /// 로그아웃·계정 삭제: RevenueCat 로그아웃 + 내 구독 상태 비움. 새 uid 는 attachUser 에서 다시 logIn 한다.
  Future<void> logOut() async {
    await _service.logOut();
    _own = false;
    _expiresAt = null;
    _productId = null;
    _status = SubscriptionStatus.none;
    notifyListeners();
  }

  Future<void> loadOffering() async {
    if (_offeringLoading) return;
    _offeringLoading = true;
    notifyListeners();
    try {
      _offering = await _service.currentOffering();
    } finally {
      _offeringLoading = false;
      _offeringTried = true;
      notifyListeners();
    }
  }

  Future<PurchaseOutcome> purchase(Package package) => _run(() => _service.purchase(package));
  Future<PurchaseOutcome> purchaseOption(SubscriptionOption option) => _run(() => _service.purchaseOption(option));
  Future<PurchaseOutcome> restore() => _run(_service.restore);

  /// 체험 오퍼(무료 구간이 있는 옵션). Play 는 체험 자격이 있는 사용자에게만 내려준다.
  static SubscriptionOption? trialOption(Package? p) =>
      p?.storeProduct.subscriptionOptions?.where((o) => o.freePhase != null).firstOrNull;

  /// 기본 요금제(바로 결제).
  static SubscriptionOption? basePlanOption(Package? p) =>
      p?.storeProduct.subscriptionOptions?.where((o) => o.isBasePlan).firstOrNull;

  Future<PurchaseOutcome> _run(Future<PurchaseOutcome> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _household?.removeListener(notifyListeners);
    super.dispose();
  }
}
