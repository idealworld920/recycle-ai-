import 'dart:convert';

import 'recycle_category.dart';

/// AI가 사진 한 장을 보고 내놓은 분리배출 판별 결과.
class RecycleResult {
  const RecycleResult({
    required this.itemName,
    required this.category,
    required this.confidence,
    required this.steps,
    required this.warnings,
    required this.tip,
    required this.createdAt,
    this.imagePath,
  });

  final String itemName;
  final RecycleCategory category;

  /// 0.0 ~ 1.0
  final double confidence;
  final List<String> steps;
  final List<String> warnings;
  final String tip;
  final DateTime createdAt;

  /// 기록 화면에서 보여줄 로컬 이미지 경로. 저장 전에는 null.
  final String? imagePath;

  int get confidencePercent => (confidence * 100).round();

  /// Gemini가 돌려준 JSON 문자열을 결과로 변환한다.
  /// 모델이 가끔 ```json 펜스를 붙여 보내므로 벗겨낸다.
  factory RecycleResult.fromAiJson(String raw, {DateTime? now}) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI 응답이 JSON 객체가 아닙니다.');
    }
    return RecycleResult.fromMap(decoded, now: now);
  }

  factory RecycleResult.fromMap(Map<String, dynamic> map, {DateTime? now}) {
    final rawConfidence = map['confidence'];
    var confidence = switch (rawConfidence) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0.0,
      _ => 0.0,
    };
    // 모델이 0~100 퍼센트로 줄 때 보정.
    if (confidence > 1.0) confidence = confidence / 100.0;
    confidence = confidence.clamp(0.0, 1.0);

    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is String
        ? (DateTime.tryParse(createdAtRaw) ?? (now ?? DateTime.now()))
        : (now ?? DateTime.now());

    return RecycleResult(
      itemName: (map['itemName'] as String?)?.trim().isNotEmpty == true
          ? (map['itemName'] as String).trim()
          : '알 수 없는 물건',
      category: RecycleCategory.fromKey(map['category'] as String?),
      confidence: confidence,
      steps: _stringList(map['steps']),
      warnings: _stringList(map['warnings']),
      tip: (map['tip'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      imagePath: map['imagePath'] as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> toMap() => {
        'itemName': itemName,
        'category': category.key,
        'confidence': confidence,
        'steps': steps,
        'warnings': warnings,
        'tip': tip,
        'createdAt': createdAt.toIso8601String(),
        if (imagePath != null) 'imagePath': imagePath,
      };

  String toJson() => jsonEncode(toMap());

  RecycleResult copyWith({String? imagePath, DateTime? createdAt}) {
    return RecycleResult(
      itemName: itemName,
      category: category,
      confidence: confidence,
      steps: steps,
      warnings: warnings,
      tip: tip,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
