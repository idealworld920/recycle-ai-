// 데이터 파일 검증. 틀린 정보가 들어가는 걸 빌드 단계에서 막는다.
//
//   dart run tool/validate_data.dart
//
// - tips.json: regionNotes 의 코드가 regions.json 에 있어야 하고, note 가 있으면 sourceUrl(https)·verifiedAt(YYYY-MM-DD) 필수, 빈 note 금지
// - regions.json: 시/도 2자리, 시/군/구 5자리 코드, 중복 금지, wasteGuideUrl 은 https
// - carbon_factors.json: 계수마다 source{org,doc,url,year} 필수, unit 은 kgCO2e/item | kgCO2e/kg, kg 단위면 typicalWeightKg 와 weightSource 함께
// 실패하면 종료 코드 1.
import 'dart:convert';
import 'dart:io';

final errors = <String>[];

void fail(String msg) => errors.add(msg);

bool validSource(dynamic s, String where) {
  if (s is! Map) {
    fail('$where: source 가 없어요');
    return false;
  }
  for (final k in ['org', 'doc', 'url']) {
    if ((s[k] as String? ?? '').trim().isEmpty) fail('$where: source.$k 가 비어 있어요');
  }
  if (!(s['url'] as String? ?? '').startsWith('https://')) fail('$where: source.url 은 https 여야 해요');
  final y = s['year'];
  if (y is! num || y < 2000) fail('$where: source.year 가 이상해요 ($y)');
  return true;
}

void main() {
  final regions = jsonDecode(File('assets/data/regions.json').readAsStringSync()) as Map<String, dynamic>;
  final codes = <String>{};
  final sidoCodes = <String>{};
  for (final s in (regions['sido'] as List).cast<Map<String, dynamic>>()) {
    final sc = s['code'] as String;
    if (!RegExp(r'^\d{2}$').hasMatch(sc)) fail('regions: 시/도 코드 형식 오류 $sc');
    if (!sidoCodes.add(sc)) fail('regions: 시/도 코드 중복 $sc');
    for (final g in (s['sigungu'] as List).cast<Map<String, dynamic>>()) {
      final c = g['code'] as String;
      if (!RegExp(r'^\d{5}$').hasMatch(c) || !c.startsWith(sc)) fail('regions: 시/군/구 코드 형식 오류 $c (${g['name']})');
      if (!codes.add(c)) fail('regions: 시/군/구 코드 중복 $c');
      final url = g['wasteGuideUrl'];
      if (url != null && !(url as String).startsWith('https://')) fail('regions: $c wasteGuideUrl 은 https 여야 해요');
    }
  }
  stdout.writeln('regions.json: 시/도 ${sidoCodes.length}, 시/군/구 ${codes.length}');

  final tips = jsonDecode(File('assets/data/tips.json').readAsStringSync()) as Map<String, dynamic>;
  var filled = 0, variants = 0;
  final tipIds = <String>{};
  for (final t in (tips['items'] as List).cast<Map<String, dynamic>>()) {
    final id = t['id'] as String;
    if (!tipIds.add(id)) fail('tips: id 중복 $id');
    if (!t.containsKey('regionNotes')) continue;
    variants++;
    final notes = (t['regionNotes'] as Map?) ?? const {};
    for (final e in notes.entries) {
      final code = e.key.toString();
      final n = (e.value as Map).cast<String, dynamic>();
      final where = 'tips[$id].regionNotes[$code]';
      if (!codes.contains(code)) fail('$where: regions.json 에 없는 코드');
      final note = (n['note'] as String? ?? '').trim();
      final url = (n['sourceUrl'] as String? ?? '').trim();
      final at = (n['verifiedAt'] as String? ?? '').trim();
      if (note.isEmpty) fail('$where: note 가 비어 있어요 (비울 거면 항목 자체를 지우세요)');
      if (!url.startsWith('https://')) fail('$where: sourceUrl 없는 note 는 저장할 수 없어요');
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(at)) fail('$where: verifiedAt 은 YYYY-MM-DD');
      if (note.length > 80) fail('$where: note 는 80자 이내');
      filled++;
    }
  }
  stdout.writeln('tips.json: 지역차 품목 $variants개, 채워진 지역 노트 $filled칸');

  final carbon = jsonDecode(File('assets/data/carbon_factors.json').readAsStringSync()) as Map<String, dynamic>;
  final factors = (carbon['factors'] as Map?) ?? const {};
  for (final e in factors.entries) {
    final id = e.key.toString();
    final f = (e.value as Map).cast<String, dynamic>();
    final where = 'carbon[$id]';
    if (!tipIds.contains(id) && !id.startsWith('category:')) fail('$where: tips id 도 category:<key> 도 아니에요');
    final v = f['kgCO2e'];
    if (v is! num || v <= 0) fail('$where: kgCO2e 가 양수여야 해요');
    final unit = f['unit'];
    if (unit != 'kgCO2e/item' && unit != 'kgCO2e/kg') fail('$where: unit 은 kgCO2e/item 또는 kgCO2e/kg');
    validSource(f['source'], where);
    if (unit == 'kgCO2e/kg') {
      final w = f['typicalWeightKg'];
      if (w is! num || w <= 0) fail('$where: kg 단위면 typicalWeightKg 가 필요해요 (없으면 이 계수는 계산에 못 써요)');
      validSource(f['weightSource'], '$where.weightSource');
    }
  }
  final pine = carbon['pine'];
  if (pine != null) {
    if (pine is! Map || pine['kgCO2PerTreePerYear'] is! num) fail('carbon.pine: kgCO2PerTreePerYear 필요');
    if (pine is Map) validSource(pine['source'], 'carbon.pine');
  }
  stdout.writeln('carbon_factors.json: 계수 ${factors.length}개, 소나무 ${pine == null ? '없음' : '있음'}');

  if (errors.isNotEmpty) {
    stderr.writeln('\n데이터 검증 실패 ${errors.length}건:');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }
  stdout.writeln('OK');
}
