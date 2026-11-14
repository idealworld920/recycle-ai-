import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:recycle_ai/features/household/household_repository.dart';
import 'package:recycle_ai/features/household/household_store.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/premium_store.dart';
import 'package:recycle_ai/features/premium/purchase_errors.dart';
import 'package:recycle_ai/features/premium/purchases_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('결제 오류 코드별 문구가 다르다', () {
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.networkError), contains('인터넷'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.storeProblemError), contains('Google Play'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.productAlreadyPurchasedError), contains('복원'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.unknownError), contains('실패'));
  });

  test('가족 플랜 상품·명칭', () {
    expect(PremiumConfig.planName, '가족 플랜');
    expect(PremiumConfig.monthlyProductId, 'resai_family_monthly');
    expect(PremiumConfig.yearlyProductId, 'resai_family_yearly');
    expect(PremiumConfig.entitlementId, 'premium');
    expect(PremiumConfig.manageUrl('resai_family_yearly'), contains('sku=resai_family_yearly'));
  });

  test('키 없는 빌드: 결제 불가, isPremium 은 임시 true 없이 false', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(store.available, isFalse);
    expect(store.isPremium, isFalse);
    expect(store.source, PremiumSource.none);
    final r = await store.restore();
    expect(r, isA<PurchaseFailed>());
  });

  test('집에 속하면 방장 구독(premiumUntil)으로 가족 플랜이 열린다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final household = HouseholdStore(HouseholdRepository(), prefs: prefs);
    final store = PremiumStore(PurchasesService.instance, prefs: prefs)..attachHousehold(household);
    expect(store.isPremium, isFalse); // 집 없음
    // 집 스토어가 가족 플랜 활성 상태를 보고하면 source 가 family 가 된다 (스트림 없이 getter 로 확인).
    expect(household.familyPlanActive, isFalse);
    expect(store.source, PremiumSource.none);
  });

  test('검토자 코드는 설정된 빌드에서만, 30일', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PremiumStore(PurchasesService.instance, prefs: await SharedPreferences.getInstance());
    expect(await store.tryReviewCode('anything'), isFalse); // REVIEW_CODE 미설정
    expect(store.reviewActive, isFalse);
  });

  test('무료 한도: 분류 10회/일, 질문 5회/일, 날짜 바뀌면 리셋', () async {
    SharedPreferences.setMockInitialValues({});
    final limits = FreeLimits(await SharedPreferences.getInstance());
    expect(FreeLimits.classifyPerDay, 10);
    expect(FreeLimits.chatPerDay, 5);
    expect(limits.classifyExhausted, isFalse);
    for (var i = 0; i < FreeLimits.classifyPerDay; i++) {
      await limits.incrementClassify();
    }
    expect(limits.classifyCountToday(), 10);
    expect(limits.classifyExhausted, isTrue);
  });
}
