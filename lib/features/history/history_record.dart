import '../../models/recycle_category.dart';
import '../../models/recycle_result.dart';

/// 요약 바에 쓰는 4분류.
enum HistoryGroup {
  recycle('재활용'),
  general('일반'),
  food('음식물'),
  special('특수');

  const HistoryGroup(this.label);
  final String label;

  static HistoryGroup of(RecycleCategory c) => switch (c) {
        RecycleCategory.food => HistoryGroup.food,
        RecycleCategory.hazardous || RecycleCategory.electronics || RecycleCategory.bulky => HistoryGroup.special,
        RecycleCategory.general || RecycleCategory.unknown => HistoryGroup.general,
        _ => HistoryGroup.recycle,
      };
}

/// 분류 기록 한 건. 기기에만 저장된다.
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.date,
    required this.itemName,
    required this.category,
    this.imageThumb,
    this.detail,
  });

  final String id;
  final DateTime date;
  final String itemName;
  final RecycleCategory category;

  /// 축소된 JPEG/PNG 를 base64 로 저장. 10KB 이하.
  final String? imageThumb;

  /// 결과 화면을 다시 열기 위한 AI 응답 원문(steps, warnings, tip, confidence).
  final Map<String, dynamic>? detail;

  HistoryGroup get group => HistoryGroup.of(category);

  /// 결과 화면에 넘길 수 있는 형태로 되돌린다.
  RecycleResult toResult() {
    final base = detail ?? const <String, dynamic>{};
    return RecycleResult.fromMap({
      ...base,
      'itemName': itemName,
      'category': category.key,
      'createdAt': date.toIso8601String(),
    });
  }

  factory HistoryRecord.fromResult(RecycleResult r, {required String id, String? imageThumb}) {
    return HistoryRecord(
      id: id,
      date: r.createdAt,
      itemName: r.itemName,
      category: r.category,
      imageThumb: imageThumb,
      detail: {
        'confidence': r.confidence,
        'steps': r.steps,
        'warnings': r.warnings,
        'tip': r.tip,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'itemName': itemName,
        'category': category.key,
        if (imageThumb != null) 'imageThumb': imageThumb,
        if (detail != null) 'detail': detail,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      itemName: json['itemName'] as String,
      category: RecycleCategory.fromKey(json['category'] as String?),
      imageThumb: json['imageThumb'] as String?,
      detail: (json['detail'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
