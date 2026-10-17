import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/places/region.dart';

void main() {
  late RegionRepository repo;

  setUpAll(() {
    repo = RegionRepository.fromJsonString(File('assets/data/bulky_waste_links.json').readAsStringSync());
  });

  test('시/구가 50개 이상이고 id 가 겹치지 않는다', () {
    expect(repo.all.length, greaterThanOrEqualTo(50));
    expect(repo.all.map((r) => r.id).toSet().length, repo.all.length);
  });

  test('서울 25개 구가 모두 있다', () {
    expect(repo.inSido('서울').length, 25);
  });

  test('링크는 https 로 시작한다', () {
    for (final r in repo.all) {
      expect(r.siteUrl, startsWith('https://'), reason: r.id);
      expect(r.bulkySearchUrl, startsWith('https://'), reason: r.id);
      expect(r.batterySearchUrl, startsWith('https://'), reason: r.id);
    }
  });

  test('id 로 찾기', () {
    expect(repo.byId('서울_마포구')?.sigungu, '마포구');
    expect(repo.byId('없음'), isNull);
    expect(repo.byId(null), isNull);
  });
}
