/// 스토어 가격(StoreProduct.price + currencyCode)으로 환산 문구를 만든다. 하드코딩 금지.
class PriceFormat {
  PriceFormat._();

  /// 통화 단위에 맞춰 반올림한 금액 문자열. KRW 는 "1,658원", 그 외는 "USD 1.99" 식.
  static String money(double amount, String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (code == 'KRW' || code == 'JPY') {
      return '${_thousands(amount.round())}${code == 'KRW' ? '원' : '엔'}';
    }
    if (code == 'USD') return '\$${amount.toStringAsFixed(2)}';
    return '$code ${amount.toStringAsFixed(2)}';
  }

  /// 연간 가격 → "월 1,658원 · 하루 55원"
  static String yearlyEquivalent(double yearly, String currencyCode) =>
      '월 ${money(yearly / 12, currencyCode)} · 하루 ${money(yearly / 365, currencyCode)}';

  /// 월간 가격 → "하루 97원"
  static String monthlyEquivalent(double monthly, String currencyCode) => '하루 ${money(monthly / 30, currencyCode)}';

  static String _thousands(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${n < 0 ? '-' : ''}$b';
  }
}
