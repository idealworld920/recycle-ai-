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

/// 결제 오류 → 사용자 문구. (스토어 SDK 가 돌아오면 코드별 분기를 다시 넣는다)
class PurchaseErrors {
  PurchaseErrors._();

  static PurchaseOutcome outcomeOf(Object e) => PurchaseFailed(generic(e));

  static String generic(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('offline') || s.contains('socket')) return '인터넷 연결을 확인해 주세요.';
    if (s.contains('cancel')) return '결제를 취소했어요.';
    return '결제에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }
}
