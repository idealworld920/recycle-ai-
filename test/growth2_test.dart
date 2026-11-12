import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/features/history/history_record.dart';
import 'package:recycle_ai/features/places/admin_region.dart';
import 'package:recycle_ai/features/places/region.dart';
import 'package:recycle_ai/features/places/region_store.dart';
import 'package:recycle_ai/features/report/carbon_factors.dart';
import 'package:recycle_ai/features/report/report_calculator.dart';
import 'package:recycle_ai/features/tips/tip_model.dart';
import 'package:recycle_ai/features/tips/tips_repository.dart';
import 'package:recycle_ai/models/recycle_category.dart';
import 'package:recycle_ai/models/waste_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final tips = TipsRepository.fromJsonString(File('assets/data/tips.json').readAsStringSync());
  final admin = AdminRegionRepository.fromJsonString(File('assets/data/regions.json').readAsStringSync());

  group('행정구역', () {
    test('공식 코드 파일 기준으로 서울 25개 구가 있고 검색이 된다', () {
      final seoul = admin.sidos.firstWhere((s) => s.code == '11');
      expect(seoul.sigungu.length, 25);
      expect(admin.byCode('11440')!.displayName, '서울 마포구');
      expect(admin.search('마포').first.code, '11440');
      expect(admin.search('수원 장안').first.name, '수원시 장안구');
      expect(admin.search('   '), isEmpty);
    });

    test('지역 선택은 코드로 저장되고, 예전 이름 기반 저장값도 이관된다', () async {
      SharedPreferences.setMockInitialValues({RegionStore.prefKey: '서울_마포구'});
      final legacy = RegionRepository.fromJsonString('{"items":[{"id":"서울_마포구","sido":"서울","sigungu":"마포구","name":"서울 마포구","siteUrl":"https://www.mapo.go.kr","bulkySearchUrl":"https://x","batterySearchUrl":"https://y"}]}');
      final store = RegionStore(await SharedPreferences.getInstance(), legacy, admin: admin);
      expect(store.code, '11440');
      expect(store.selected?.id, '서울_마포구');

      Map<String, dynamic>? saved;
      store.onRemoteSave = (d) async => saved = d;
      await store.selectAdmin(admin.byCode('11680'));
      expect(saved, {'sido': '서울특별시', 'sigungu': '강남구', 'code': '11680'});
      expect((await SharedPreferences.getInstance()).getString(RegionStore.codePrefKey), '11680');
      expect(store.selected, isNull, reason: '예전 링크 데이터에 없는 지역이면 null');
    });

    test('서버 값은 기기에 없을 때만 받아온다', () async {
      SharedPreferences.setMockInitialValues({});
      final store = RegionStore(await SharedPreferences.getInstance(), RegionRepository.fromJsonString('{"items":[]}'), admin: admin);
      store.adoptRemote({'code': '11110'});
      expect(store.code, '11110');
      store.adoptRemote({'code': '11680'});
      expect(store.code, '11110');
    });
  });

  group('지역 노트', () {
    test('출처 없는 노트는 돌려주지 않는다', () {
      final tip = Tip.fromJson({
        'id': 'x', 'name': 'x', 'category': '재활용', 'steps': ['a'],
        'regionNotes': {
          '11110': {'note': '좋아요', 'sourceUrl': 'https://www.jongno.go.kr/x', 'verifiedAt': '2026-11-12'},
          '11140': {'note': '출처 없음', 'sourceUrl': '', 'verifiedAt': '2026-11-12'},
        },
      });
      expect(tip.isRegionVariant, isTrue);
      expect(tip.noteFor('11110')!.note, '좋아요');
      expect(tip.noteFor('11140'), isNull);
      expect(tip.noteFor(null), isNull);
      expect(Tip.fromJson({'id': 'y', 'name': 'y', 'category': '재활용', 'steps': []}).isRegionVariant, isFalse);
    });

    test('지자체마다 다른 5개 품목에 regionNotes 가 선언돼 있다', () {
      for (final id in ['cup_noodle', 'ice_pack', 'aseptic_pack', 'paper_cup', 'styrofoam']) {
        expect(tips.all.firstWhere((t) => t.id == id).isRegionVariant, isTrue, reason: id);
      }
    });
  });

  group('월간 리포트', () {
    HistoryRecord rec(String name, RecycleCategory c, DateTime d) => HistoryRecord(id: '$name-${d.toIso8601String()}', date: d, itemName: name, category: c);

    test('총계·재활용률·지난달 대비·TOP3·체크인을 계산한다', () {
      final oct = DateTime(2026, 10, 15), sep = DateTime(2026, 9, 10);
      final report = ReportCalculator.build(
        month: DateTime(2026, 10, 1),
        history: [
          rec('생수 페트병', RecycleCategory.pet, oct), rec('페트병', RecycleCategory.pet, oct), rec('컵라면 용기', RecycleCategory.general, oct),
          rec('바나나 껍질', RecycleCategory.food, oct),
          rec('택배 상자', RecycleCategory.paper, sep), rec('컵라면 용기', RecycleCategory.general, sep),
        ],
        checkinDates: {'2026-10-03', '2026-10-10', '2026-09-20'},
        schedule: null,
        tips: tips,
        factors: const CarbonFactors(factors: {}, pine: null),
      );
      expect(report.total, 4);
      expect(report.prevTotal, 2);
      expect(report.recycleRate, 50);
      expect(report.prevRecycleRate, 50);
      expect(report.rateChange, 0);
      expect(report.improvedOrSame, isTrue);
      expect(report.topItems.first.name, '투명 페트병');
      expect(report.topItems.first.count, 2);
      expect(report.checkinCount, 2);
      expect(report.counts[WasteGroup.recycle], 2);
      expect(report.carbon.showable, isFalse, reason: '계수가 없으면 숨김');
    });

    test('계수가 있는 품목이 절반 미만이면 탄소 섹션을 숨기고, 절반 이상이면 합산한다', () {
      final f = CarbonFactors.fromJsonString('''
      {"pine":{"kgCO2PerTreePerYear":6.6,"source":{"org":"테스트","doc":"문서","url":"https://example.org/p","year":2020}},
       "factors":{"pet_bottle":{"kgCO2e":0.05,"unit":"kgCO2e/item","basis":"1개","source":{"org":"테스트","doc":"문서","url":"https://example.org/a","year":2021}},
                  "nosrc":{"kgCO2e":9,"unit":"kgCO2e/item","source":{"org":"","doc":"","url":"","year":0}},
                  "category:paper":{"kgCO2e":1.0,"unit":"kgCO2e/kg","basis":"kg","source":{"org":"t","doc":"d","url":"https://example.org/b","year":2021}}}}''');
      expect(f.factors.containsKey('nosrc'), isFalse, reason: '출처 없는 계수는 버린다');
      expect(f.factors['category:paper']!.perItemKg, isNull, reason: 'kg 단위인데 무게 출처가 없으면 계산 불가');
      final oct = DateTime(2026, 10, 15);
      final low = ReportCalculator.build(month: oct, history: [rec('생수 페트병', RecycleCategory.pet, oct), rec('컵라면 용기', RecycleCategory.general, oct), rec('택배 상자', RecycleCategory.paper, oct)], checkinDates: {}, schedule: null, tips: tips, factors: f);
      expect(low.carbon.coveredCount, 1);
      expect(low.carbon.showable, isFalse);
      final high = ReportCalculator.build(month: oct, history: [rec('생수 페트병', RecycleCategory.pet, oct), rec('페트병', RecycleCategory.pet, oct), rec('컵라면 용기', RecycleCategory.general, oct)], checkinDates: {}, schedule: null, tips: tips, factors: f);
      expect(high.carbon.showable, isTrue);
      expect(high.carbon.kg, closeTo(0.10, 1e-9));
      expect(high.carbon.trees, closeTo(0.10 / 6.6, 1e-9));
      expect(high.carbon.used.single.label, '투명 페트병');
    });

    test('재활용률이 떨어지면 idle 리뿅이', () {
      final oct = DateTime(2026, 10, 15), sep = DateTime(2026, 9, 10);
      final r = ReportCalculator.build(month: oct, history: [rec('컵라면 용기', RecycleCategory.general, oct), rec('페트병', RecycleCategory.pet, sep)], checkinDates: {}, schedule: null, tips: tips, factors: const CarbonFactors(factors: {}, pine: null));
      expect(r.rateChange, -100);
      expect(r.improvedOrSame, isFalse);
    });
  });
}
