import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_errors.dart';
import 'purchases_service.dart';

/// 구독 상태의 진실은 RevenueCat SDK. Firestore users/{uid}.premium 은 웹훅(Cloud Function)만 갱신한다.
class PremiumStore extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  PremiumStore(this._service, {SharedPreferences? prefs}) : _prefs = prefs {
    _reviewUntil = _prefs?.getInt(reviewPrefKey) ?? 0;
    _sub = _service.customerInfoStream.listen((info) {
      _premium = PurchasesService.hasPremium(info);
      _expiresAt = info.entitlements.active[PremiumConfig.entitlementId]?.expirationDate;
      notifyListeners();
    });
  }

  static const reviewPrefKey = 'review_premium_until';

  final PurchasesService _service;
  final SharedPreferences? _prefs;
  int _reviewUntil = 0;
  StreamSubscription<CustomerInfo>? _sub;
  bool _premium = false;
  String? _expiresAt;
  Offering? _offering;
  bool _busy = false;

  bool get isPremium => PremiumConfig.debugPremium || _premium || reviewActive;

  /// 검토자 코드로 열린 임시 프리미엄.
  bool get reviewActive => _reviewUntil > DateTime.now().millisecondsSinceEpoch;

  /// 설정 → 앱 정보에서 입력한 코드. 맞으면 [PremiumConfig.reviewDays] 동안 프리미엄.
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
  Offering? get offering => _offering;

  Package? get monthly => _offering?.monthly ?? _find(PremiumConfig.monthlyProductId);
  Package? get yearly => _offering?.annual ?? _find(PremiumConfig.yearlyProductId);

  Package? _find(String productId) =>
      _offering?.availablePackages.where((p) => p.storeProduct.identifier.startsWith(productId)).firstOrNull;

  /// uid 가 정해지면 호출. 처음엔 configure, 이후엔 alias(logIn).
  Future<void> attachUser(String? uid) async {
    if (uid == null || !_service.available) return;
    if (!_service.configured) {
      await _service.configure(uid);
    } else {
      await _service.logIn(uid);
    }
    final info = await _service.customerInfo();
    if (info != null) {
      _premium = PurchasesService.hasPremium(info);
      _expiresAt = info.entitlements.active[PremiumConfig.entitlementId]?.expirationDate;
    }
    notifyListeners();
  }

  Future<void> loadOffering() async {
    _offering = await _service.currentOffering();
    notifyListeners();
  }

  Future<PurchaseOutcome> purchase(Package package) => _run(() => _service.purchase(package));
  Future<PurchaseOutcome> purchaseOption(SubscriptionOption option) => _run(() => _service.purchaseOption(option));

  /// 체험 오퍼(무료 구간이 있는 옵션). Play 는 체험 자격이 있는 사용자에게만 내려준다.
  static SubscriptionOption? trialOption(Package? p) =>
      p?.storeProduct.subscriptionOptions?.where((o) => o.freePhase != null).firstOrNull;

  /// 기본 요금제(바로 결제).
  static SubscriptionOption? basePlanOption(Package? p) =>
      p?.storeProduct.subscriptionOptions?.where((o) => o.isBasePlan).firstOrNull;
  Future<PurchaseOutcome> restore() => _run(_service.restore);

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
    super.dispose();
  }
}
