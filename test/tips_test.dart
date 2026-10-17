import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/tips/tip_model.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';

void main() {
  late TipsRepository repo;

  setUpAll(() {
    repo = TipsRepository.fromJsonString(File('assets/data/tips.json').readAsStringSync());
  });

  test('품목이 40개 이상이고 id 가 겹치지 않는다', () {
    expect(repo.all.length, greaterThanOrEqualTo(40));
    expect(repo.all.map((t) => t.id).toSet().length, repo.all.length);
  });

  test('필수 품목이 모두 들어 있다', () {
    const required = [
      '페트병', '캔', '종이', '종이팩', '멸균팩', '유리병', '비닐', '스티로폼', '플라스틱 용기', '컵라면 용기',
      '치킨 뼈', '깨진 유리', '거울', '전구', '건전지', '의약품', '아이스팩', '영수증', '택배 상자', '커피컵',
      '마스크', '옷', '우산', '칫솔',
    ];
    for (final name in required) {
      expect(repo.search(name), isNotEmpty, reason: '$name 없음');
    }
  });

  test('steps 는 3개 이하, 각 20자 내외', () {
    for (final t in repo.all) {
      expect(t.steps.length, inInclusiveRange(1, 3), reason: t.id);
      for (final s in t.steps) {
        expect(s.length, lessThanOrEqualTo(24), reason: '${t.id}: $s');
      }
    }
  });

  test('검색은 별칭으로도 된다', () {
    expect(repo.search('생수병').first.id, 'pet_bottle');
    expect(repo.search('닭뼈').first.id, 'chicken_bone');
    expect(repo.search('KF94').first.id, 'mask');
    expect(repo.search('  보조 배터리 ').first.id, 'battery');
  });

  test('분류 필터가 적용된다', () {
    final food = repo.search('', category: TipCategory.food);
    expect(food, isNotEmpty);
    expect(food.every((t) => t.category == TipCategory.food), isTrue);
  });

  test('AI 품목명과 팁을 매칭한다', () {
    expect(repo.findForItem('생수 페트병')?.id, 'pet_bottle');
    expect(repo.findForItem('먹다 남은 치킨 뼈')?.id, 'chicken_bone');
    expect(repo.findForItem('컵라면 용기')?.id, 'cup_noodle');
    expect(repo.findForItem('우주선 부품'), isNull);
  });
}
