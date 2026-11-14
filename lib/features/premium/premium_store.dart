import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_errors.dart';
import 'purchases_service.dart';

/// 프리미엄 상태. 1.1.0 에는 구독이 없어서 `PREMIUM_DEBUG` 또는 검토자 코드로만 열린다.
/// (구독이 돌아오면 RevenueCat SDK 가 진실이 되고, Firestore users/{uid}.premium 은 웹훅만 갱신한다.)
class PremiumStore extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  PremiumStore(this._service, {SharedPreferences? prefs}) : _prefs = prefs {
    _reviewUntil = _prefs?.getInt(reviewPrefKey) ?? 0;
  }

  static const reviewPrefKey = 'review_premium_until';

  final PurchasesService _service;
  final SharedPreferences? _prefs;
  int _reviewUntil = 0;
  bool _busy = false;

  bool get isPremium => PremiumConfig.debugPremium || reviewActive;

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

  /// 결제 가능 여부. 이 버전에서는 항상 false (페이월이 "다음 업데이트" 안내를 보여준다).
  bool get available => _service.available;
  bool get busy => _busy;
  String? get expiresAt => null;

  /// uid 가 정해지면 호출. 결제 SDK 가 없으니 할 일이 없다.
  Future<void> attachUser(String? uid) async {}

  Future<PurchaseOutcome> purchase() => _run(_service.purchase);
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
}
