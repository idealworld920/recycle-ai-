import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchase_errors.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('결제 오류 문구', () {
    expect(PurchaseErrors.generic(Exception('network down')), contains('인터넷'));
    expect(PurchaseErrors.generic(Exception('user cancelled')), contains('취소'));
    expect(PurchaseErrors.generic(Exception('boom')), contains('실패'));
  });

  test('1.1.0 에는 구독이 없다: 결제 불가, 복원은 안내 문구로 실패', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(store.available, isFalse);
    expect(store.isPremium, isFalse);
    final r = await store.restore();
    expect(r, isA<PurchaseFailed>());
    expect((r as PurchaseFailed).message, PremiumConfig.comingSoon);
  });

  test('무료 분류 한도는 하루 5회, 날짜가 바뀌면 리셋', () async {
    SharedPreferences.setMockInitialValues({});
    final limits = FreeLimits(await SharedPreferences.getInstance());
    expect(limits.classifyExhausted, isFalse);
    for (var i = 0; i < FreeLimits.classifyPerDay; i++) {
      await limits.incrementClassify();
    }
    expect(limits.classifyCountToday(), 5);
    expect(limits.classifyExhausted, isTrue);
    expect(FreeLimits.chatPerDay, 3);
  });
}
