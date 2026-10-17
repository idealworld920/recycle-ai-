import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/data/recycling_guide.dart';
import 'package:recycle_ai/models/recycle_category.dart';

void main() {
  test('unknown을 제외한 모든 분류에 가이드가 있다', () {
    for (final c in RecycleCategory.values) {
      if (c == RecycleCategory.unknown) continue;
      expect(guideFor(c), isNotNull, reason: '${c.label} 가이드 없음');
    }
  });

  test('가이드마다 버리는 방법이 최소 2단계 있다', () {
    for (final g in recyclingGuide) {
      expect(g.howTo.length, greaterThanOrEqualTo(2), reason: g.category.label);
      expect(g.allowed, isNotEmpty, reason: g.category.label);
    }
  });

  test('분류 키는 중복이 없다', () {
    final keys = RecycleCategory.allKeys;
    expect(keys.toSet().length, keys.length);
  });
}
