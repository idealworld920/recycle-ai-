import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 출처 한 건. 기관명 + 문서명 + URL + 연도 전부 있어야 유효.
class FactorSource {
  const FactorSource({required this.org, required this.doc, required this.url, required this.year});

  final String org;
  final String doc;
  final String url;
  final int year;

  bool get isValid => org.isNotEmpty && doc.isNotEmpty && url.startsWith('https://') && year > 2000;

  factory FactorSource.fromJson(Map<String, dynamic> j) => FactorSource(
        org: (j['org'] as String?) ?? '',
        doc: (j['doc'] as String?) ?? '',
        url: (j['url'] as String?) ?? '',
        year: (j['year'] as num?)?.toInt() ?? 0,
      );

  String get label => '$org, $doc ($year)';
}

/// 품목(또는 재질) 하나의 온실가스 감축 계수.
class CarbonFactor {
  const CarbonFactor({
    required this.id,
    required this.kgCO2e,
    required this.unit,
    required this.basis,
    required this.source,
    this.typicalWeightKg,
    this.weightSource,
  });

  final String id;
  final double kgCO2e;

  /// "kgCO2e/item" 또는 "kgCO2e/kg".
  final String unit;
  final String basis;
  final FactorSource source;

  /// 단위가 kg 당일 때 1개 무게. 이것도 출처가 있어야만 쓴다.
  final double? typicalWeightKg;
  final FactorSource? weightSource;

  /// 1개당 kgCO2e. 계산에 쓸 수 없으면 null.
  double? get perItemKg {
    if (unit == 'kgCO2e/item') return kgCO2e;
    if (unit == 'kgCO2e/kg' && typicalWeightKg != null && (weightSource?.isValid ?? false)) return kgCO2e * typicalWeightKg!;
    return null;
  }

  factory CarbonFactor.fromJson(String id, Map<String, dynamic> j) => CarbonFactor(
        id: id,
        kgCO2e: (j['kgCO2e'] as num).toDouble(),
        unit: j['unit'] as String,
        basis: (j['basis'] as String?) ?? '',
        source: FactorSource.fromJson((j['source'] as Map).cast<String, dynamic>()),
        typicalWeightKg: (j['typicalWeightKg'] as num?)?.toDouble(),
        weightSource: j['weightSource'] == null ? null : FactorSource.fromJson((j['weightSource'] as Map).cast<String, dynamic>()),
      );
}

/// 소나무 1그루 연간 CO2 흡수량.
class PineFactor {
  const PineFactor({required this.kgPerTreePerYear, required this.source, this.basis = ''});

  final double kgPerTreePerYear;
  final FactorSource source;
  final String basis;
}

/// assets/data/carbon_factors.json. 출처 없는 항목은 로드 단계에서 버린다.
class CarbonFactors {
  const CarbonFactors({required this.factors, required this.pine});

  static const assetPath = 'assets/data/carbon_factors.json';

  final Map<String, CarbonFactor> factors;
  final PineFactor? pine;

  bool get isEmpty => factors.isEmpty;

  /// 팁 id → 없으면 `category:<key>` 로 찾는다.
  CarbonFactor? lookup({String? tipId, String? categoryKey}) =>
      (tipId == null ? null : factors[tipId]) ?? (categoryKey == null ? null : factors['category:$categoryKey']);

  static Future<CarbonFactors> load() async {
    try {
      return CarbonFactors.fromJsonString(await rootBundle.loadString(assetPath));
    } catch (_) {
      return const CarbonFactors(factors: {}, pine: null);
    }
  }

  factory CarbonFactors.fromJsonString(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, CarbonFactor>{};
    for (final e in ((j['factors'] as Map?) ?? const {}).entries) {
      try {
        final f = CarbonFactor.fromJson(e.key.toString(), (e.value as Map).cast<String, dynamic>());
        if (f.source.isValid && f.kgCO2e > 0) out[f.id] = f;
      } catch (_) {}
    }
    PineFactor? pine;
    final p = j['pine'];
    if (p is Map) {
      final src = FactorSource.fromJson((p['source'] as Map).cast<String, dynamic>());
      final v = (p['kgCO2PerTreePerYear'] as num?)?.toDouble();
      if (src.isValid && v != null && v > 0) pine = PineFactor(kgPerTreePerYear: v, source: src, basis: (p['basis'] as String?) ?? '');
    }
    return CarbonFactors(factors: out, pine: pine);
  }
}
