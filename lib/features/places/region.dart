import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'admin_region.dart';

/// 시/구 하나와 그 지자체의 안내 링크.
class Region {
  const Region({
    required this.id,
    required this.sido,
    required this.sigungu,
    required this.name,
    required this.siteUrl,
    required this.bulkySearchUrl,
    required this.batterySearchUrl,
    this.bulkyPhone = '',
    this.note = '',
  });

  final String id;
  final String sido;
  final String sigungu;
  final String name;

  /// 지자체 공식 홈페이지.
  final String siteUrl;

  /// 대형폐기물 신고 페이지로 가는 검색 링크. 지자체 페이지 주소가 자주 바뀌어 검색이 가장 안정적이다.
  final String bulkySearchUrl;
  final String batterySearchUrl;
  final String bulkyPhone;
  final String note;

  /// 옛 링크 데이터에 없는 시/군/구용. 행정구역 정보로 검색 링크를 만들고, 홈페이지는 분리배출 안내 URL 의 도메인에서 딴다.
  /// 구(區)는 전국에 같은 이름이 많아 시도를 붙여 검색하고, 시·군은 이름만으로 검색한다.
  factory Region.fallbackFor(AdminSigungu a) {
    final query = a.name.endsWith('구') ? '${a.sidoShort} ${a.name}' : a.name;
    String search(String what) => 'https://search.naver.com/search.naver?query=${Uri.encodeQueryComponent('$query $what')}';
    final guide = a.wasteGuideUrl;
    final site = guide == null ? search('홈페이지') : Uri.tryParse(guide)?.replace(path: '/', query: null, fragment: null).toString().replaceAll(RegExp(r'/$'), '') ?? search('홈페이지');
    return Region(
      id: a.code,
      sido: a.sidoShort,
      sigungu: a.name,
      name: a.displayName,
      siteUrl: site,
      bulkySearchUrl: search('대형폐기물 배출 신고'),
      batterySearchUrl: search('폐건전지 아이스팩 수거함'),
    );
  }

  /// 옛 데이터의 시도명("전남", "광주")이 새 행정구역("전남광주통합특별시"/"전남광주")에 속하는가.
  static bool sidoMatches(String legacySido, AdminSigungu a) =>
      legacySido == a.sidoShort || a.sidoShort.contains(legacySido) || a.sidoName.startsWith(legacySido) || legacySido.contains(a.sidoShort);

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        sido: j['sido'] as String,
        sigungu: j['sigungu'] as String,
        name: j['name'] as String,
        siteUrl: j['siteUrl'] as String,
        bulkySearchUrl: j['bulkySearchUrl'] as String,
        batterySearchUrl: j['batterySearchUrl'] as String,
        bulkyPhone: (j['bulkyPhone'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
      );
}

/// assets/data/bulky_waste_links.json 로더.
class RegionRepository {
  RegionRepository._(this._regions);

  static const assetPath = 'assets/data/bulky_waste_links.json';

  final List<Region> _regions;

  List<Region> get all => List.unmodifiable(_regions);
  List<String> get sidos => {for (final r in _regions) r.sido}.toList(growable: false);
  List<Region> inSido(String sido) => _regions.where((r) => r.sido == sido).toList(growable: false);
  Region? byId(String? id) => id == null ? null : _regions.where((r) => r.id == id).firstOrNull;

  static Future<RegionRepository> load() async => RegionRepository.fromJsonString(await rootBundle.loadString(assetPath));

  factory RegionRepository.fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return RegionRepository._((decoded['items'] as List).cast<Map<String, dynamic>>().map(Region.fromJson).toList(growable: false));
  }
}
