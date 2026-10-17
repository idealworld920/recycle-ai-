import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchase_errors.dart';
import 'purchases_service.dart';

/// 구독 상태의 진실은 RevenueCat SDK. Firestore users/{uid}.premium 은 웹훅(Cloud Function)만 갱신한다.
class PremiumStore extends ChangeNotifier {
  PremiumStore(this._service) {
    _sub = _service.customerInfoStream.listen((info) {
      _premium = PurchasesService.hasPremium(info);
      _expiresAt = info.entitlements.active[PremiumConfig.entitlementId]?.expirationDate;
      notifyListeners();
    });
  }

  final PurchasesService _service;
  StreamSubscription<CustomerInfo>? _sub;
  bool _premium = false;
  String? _expiresAt;
  Offering? _offering;
  bool _busy = false;

  bool get isPremium => PremiumConfig.debugPremium || _premium;
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
