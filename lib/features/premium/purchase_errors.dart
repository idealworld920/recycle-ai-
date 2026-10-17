import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// 결제 결과. 취소·대기·실패를 구분해 문구를 다르게 보여준다.
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess();
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

/// 결제 수단 승인 대기 등. 나중에 자동 반영.
class PurchasePending extends PurchaseOutcome {
  const PurchasePending();
}

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.message);
  final String message;
}

class PurchaseErrors {
  PurchaseErrors._();

  static PurchaseOutcome outcomeOf(Object e) {
    if (e is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
        PurchasesErrorCode.paymentPendingError => const PurchasePending(),
        _ => PurchaseFailed(messageFor(code)),
      };
    }
    return PurchaseFailed(generic(e));
  }

  static String messageFor(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.networkError || PurchasesErrorCode.offlineConnectionError => '인터넷 연결을 확인해 주세요.',
        PurchasesErrorCode.storeProblemError => 'Google Play 에 잠시 문제가 있어요. 조금 뒤 다시 시도해 주세요.',
        PurchasesErrorCode.purchaseNotAllowedError => '이 기기에서는 결제를 할 수 없어요. Play 스토어 계정과 결제 설정을 확인해 주세요.',
        PurchasesErrorCode.purchaseInvalidError => '결제 정보가 올바르지 않아요. 결제 수단을 확인해 주세요.',
        PurchasesErrorCode.productNotAvailableForPurchaseError => '지금은 이 상품을 살 수 없어요. 앱을 최신 버전으로 업데이트해 주세요.',
        PurchasesErrorCode.productAlreadyPurchasedError => '이미 구독 중이에요. "구매 복원"을 눌러 주세요.',
        PurchasesErrorCode.receiptAlreadyInUseError => '이 구매는 다른 계정에 연결돼 있어요. 그 계정으로 복원해 주세요.',
        PurchasesErrorCode.configurationError || PurchasesErrorCode.invalidCredentialsError => '결제 설정이 아직 안 됐어요. 곧 준비할게요.',
        _ => '결제에 실패했어요. 잠시 후 다시 시도해 주세요.',
      };

  static String generic(Object e) {
    final s = e.toString();
    if (s.contains('network')) return '인터넷 연결을 확인해 주세요.';
    return '결제에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }
}
