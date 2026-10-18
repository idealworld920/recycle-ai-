import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('REVIEW_CODE 가 비어 있으면 어떤 코드도 프리미엄을 열지 못한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(await store.tryReviewCode('anything'), isFalse);
    expect(store.isPremium, isFalse);
  });

  test('저장된 검토 기간이 남아 있으면 프리미엄, 지났으면 아니다', () async {
    final future = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({PremiumStore.reviewPrefKey: future});
    final active = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(active.reviewActive, isTrue);
    expect(active.isPremium, isTrue);

    final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({PremiumStore.reviewPrefKey: past});
    final expired = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(expired.reviewActive, isFalse);
  });
}
