import '../../models/waste_group.dart';

/// 팁 분류. tips.json 의 category 문자열과 1:1 대응.
enum TipCategory {
  recycle('재활용', WasteGroup.recycle),
  general('일반쓰레기', WasteGroup.general),
  food('음식물', WasteGroup.food),
  special('특수', WasteGroup.special);

  const TipCategory(this.label, this.group);

  final String label;
  final WasteGroup group;

  static TipCategory? fromLabel(String? label) {
    for (final c in TipCategory.values) {
      if (c.label == label) return c;
    }
    return null;
  }
}

/// 특정 시/군/구의 배출 기준 한 줄. 구청 공식 안내 페이지에서 직접 확인한 것만 들어간다.
class RegionNote {
  const RegionNote({required this.note, required this.sourceUrl, required this.verifiedAt});

  final String note;
  final String sourceUrl;

  /// YYYY-MM-DD
  final String verifiedAt;

  factory RegionNote.fromJson(Map<String, dynamic> j) => RegionNote(
        note: (j['note'] as String?)?.trim() ?? '',
        sourceUrl: (j['sourceUrl'] as String?)?.trim() ?? '',
        verifiedAt: (j['verifiedAt'] as String?)?.trim() ?? '',
      );

  bool get isValid => note.isNotEmpty && sourceUrl.startsWith('https://') && verifiedAt.isNotEmpty;
}

/// 품목 하나의 분리배출 팁.
class Tip {
  const Tip({
    required this.id,
    required this.name,
    required this.aliases,
    required this.category,
    required this.steps,
    this.caution = '',
    this.localNote = '',
    this.regionNotes,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final TipCategory category;
  final List<String> steps;
  final String caution;
  final String localNote;

  /// 시군구 코드 → 그 지역 기준. 키가 있으면(비어 있어도) "지자체마다 다른 품목" 이라는 뜻.
  final Map<String, RegionNote>? regionNotes;

  bool get hasCaution => caution.trim().isNotEmpty;
  bool get hasLocalNote => localNote.trim().isNotEmpty;

  /// 지자체별로 기준이 갈리는 품목인가 (regionNotes 필드가 있는 품목).
  bool get isRegionVariant => regionNotes != null;

  /// 검증된 지역 노트만. 출처 없는 노트는 돌려주지 않는다.
  RegionNote? noteFor(String? code) {
    if (code == null) return null;
    final n = regionNotes?[code];
    return n != null && n.isValid ? n : null;
  }

  /// 검색에 쓰는 모든 이름 (품목명 + 별칭).
  List<String> get allNames => [name, ...aliases];

  factory Tip.fromJson(Map<String, dynamic> json) {
    final category = TipCategory.fromLabel(json['category'] as String?);
    if (category == null) {
      throw FormatException('알 수 없는 category: ${json['category']} (id: ${json['id']})');
    }
    return Tip(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List? ?? const []).map((e) => e.toString()).toList(growable: false),
      category: category,
      steps: (json['steps'] as List? ?? const []).map((e) => e.toString()).toList(growable: false),
      caution: (json['caution'] as String?) ?? '',
      localNote: (json['localNote'] as String?) ?? '',
      regionNotes: json.containsKey('regionNotes')
          ? ((json['regionNotes'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), RegionNote.fromJson((v as Map).cast<String, dynamic>())))
          : null,
    );
  }
}
