import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 시/도 하나. 행정표준코드 2자리.
class AdminSido {
  const AdminSido({required this.code, required this.name, required this.short, required this.sigungu});

  final String code;
  final String name;

  /// 표시용 짧은 이름 (서울, 경기 …).
  final String short;
  final List<AdminSigungu> sigungu;
}

/// 시/군/구 하나. 행정표준코드(법정동코드 앞 5자리).
class AdminSigungu {
  const AdminSigungu({
    required this.code,
    required this.name,
    required this.sidoCode,
    required this.sidoName,
    required this.sidoShort,
    this.wasteGuideUrl,
  });

  final String code;
  final String name;
  final String sidoCode;
  final String sidoName;
  final String sidoShort;

  /// 구청 공식 분리배출 안내 페이지. 확인된 곳만 값이 있다.
  final String? wasteGuideUrl;

  /// "서울 마포구" 처럼 보여줄 이름.
  String get displayName => '$sidoShort $name';

  /// users/{uid}.region 에 저장하는 형태.
  Map<String, dynamic> toUserDoc() => {'sido': sidoName, 'sigungu': name, 'code': code};
}

/// assets/data/regions.json 로더.
///
/// 형식: {"sido":[{"code":"11","name":"서울특별시","short":"서울","sigungu":[{"code":"11110","name":"종로구","wasteGuideUrl":"…"}]}]}
class AdminRegionRepository {
  AdminRegionRepository._(this.sidos, this._byCode);

  static const assetPath = 'assets/data/regions.json';

  final List<AdminSido> sidos;
  final Map<String, AdminSigungu> _byCode;

  List<AdminSigungu> get all => _byCode.values.toList(growable: false);
  AdminSigungu? byCode(String? code) => code == null ? null : _byCode[code];
  bool get isEmpty => _byCode.isEmpty;

  /// "마포", "서울 마포구", "수원 장안" 전부 잡힌다. 공백으로 나눈 토큰이 모두 들어 있으면 일치, 이름이 첫 토큰으로 시작하면 우선.
  List<AdminSigungu> search(String query) {
    final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return const [];
    bool hit(AdminSigungu s) => tokens.every((tok) => s.name.contains(tok) || s.sidoName.contains(tok) || s.sidoShort.contains(tok));
    bool starts(AdminSigungu s) => s.name.startsWith(tokens.first) || s.name.contains(' ${tokens.first}');
    final all = this.all.where(hit).toList();
    return [...all.where(starts), ...all.where((s) => !starts(s))];
  }

  static Future<AdminRegionRepository> load() async => AdminRegionRepository.fromJsonString(await rootBundle.loadString(assetPath));

  factory AdminRegionRepository.fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final sidos = <AdminSido>[];
    final byCode = <String, AdminSigungu>{};
    for (final s in (decoded['sido'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final list = <AdminSigungu>[];
      for (final g in (s['sigungu'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final item = AdminSigungu(
          code: g['code'] as String,
          name: g['name'] as String,
          sidoCode: s['code'] as String,
          sidoName: s['name'] as String,
          sidoShort: (s['short'] as String?) ?? s['name'] as String,
          wasteGuideUrl: (g['wasteGuideUrl'] as String?)?.trim().isNotEmpty == true ? (g['wasteGuideUrl'] as String).trim() : null,
        );
        list.add(item);
        byCode[item.code] = item;
      }
      sidos.add(AdminSido(code: s['code'] as String, name: s['name'] as String, short: (s['short'] as String?) ?? s['name'] as String, sigungu: list));
    }
    return AdminRegionRepository._(sidos, byCode);
  }

  static AdminRegionRepository empty() => AdminRegionRepository._(const [], const {});
}
