import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:recycle_ai/features/premium/free_limits.dart';
import 'package:recycle_ai/features/premium/purchase_errors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('결제 오류 코드별 문구가 다르다', () {
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.networkError), contains('인터넷'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.storeProblemError), contains('Google Play'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.productAlreadyPurchasedError), contains('복원'));
    expect(PurchaseErrors.messageFor(PurchasesErrorCode.unknownError), contains('실패'));
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
