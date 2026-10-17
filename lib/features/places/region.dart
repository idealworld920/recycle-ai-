import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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
