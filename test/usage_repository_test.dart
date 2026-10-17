import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/chat/usage_repository.dart';

void main() {
  test('날짜 키는 KST 기준이라 UTC 자정 전후가 같은 날로 묶이지 않는다', () {
    // UTC 15:00 = KST 다음날 00:00
    expect(UsageRepository.dayKey(DateTime.utc(2026, 10, 17, 14, 59)), '2026-10-17');
    expect(UsageRepository.dayKey(DateTime.utc(2026, 10, 17, 15, 0)), '2026-10-18');
  });

  test('월·일은 두 자리로 채운다', () {
    expect(UsageRepository.dayKey(DateTime.utc(2026, 1, 2, 3)), '2026-01-02');
  });

  test('하루 한도는 5회', () {
    expect(UsageRepository.dailyLimit, 5);
  });
}
