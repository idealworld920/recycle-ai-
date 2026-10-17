import 'package:flutter/material.dart';

/// 팁 분류. tips.json 의 category 문자열과 1:1 대응.
enum TipCategory {
  recycle('재활용', Color(0xFF16A34A)),
  general('일반쓰레기', Color(0xFF6B7280)),
  food('음식물', Color(0xFFF97316)),
  special('특수', Color(0xFFE5484D));

  const TipCategory(this.label, this.color);

  final String label;
  final Color color;

  static TipCategory? fromLabel(String? label) {
    for (final c in TipCategory.values) {
      if (c.label == label) return c;
    }
    return null;
  }
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
  });

  final String id;
  final String name;
  final List<String> aliases;
  final TipCategory category;
  final List<String> steps;
  final String caution;
  final String localNote;

  bool get hasCaution => caution.trim().isNotEmpty;
  bool get hasLocalNote => localNote.trim().isNotEmpty;

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
    );
  }
}
