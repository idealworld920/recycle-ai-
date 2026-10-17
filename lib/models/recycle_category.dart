import 'package:flutter/material.dart';

/// 한국 분리배출 기준에 맞춘 배출 분류.
enum RecycleCategory {
  pet('pet', '투명 페트병', Icons.water_drop_outlined, Color(0xFF0288D1)),
  plastic('plastic', '플라스틱', Icons.recycling, Color(0xFF1E88E5)),
  paper('paper', '종이', Icons.description_outlined, Color(0xFF8D6E63)),
  paperPack('paper_pack', '종이팩', Icons.local_drink_outlined, Color(0xFFA1887F)),
  can('can', '캔 · 고철', Icons.hardware_outlined, Color(0xFF546E7A)),
  glass('glass', '유리병', Icons.wine_bar_outlined, Color(0xFF00897B)),
  vinyl('vinyl', '비닐', Icons.shopping_bag_outlined, Color(0xFF7CB342)),
  styrofoam('styrofoam', '스티로폼', Icons.inventory_2_outlined, Color(0xFF9E9E9E)),
  food('food', '음식물 쓰레기', Icons.restaurant_outlined, Color(0xFFF4511E)),
  hazardous('hazardous', '유해 폐기물', Icons.warning_amber_outlined, Color(0xFFE53935)),
  electronics('electronics', '폐가전', Icons.devices_other_outlined, Color(0xFF5E35B1)),
  clothing('clothing', '의류', Icons.checkroom_outlined, Color(0xFFD81B60)),
  bulky('bulky', '대형 폐기물', Icons.weekend_outlined, Color(0xFF6D4C41)),
  general('general', '일반 쓰레기', Icons.delete_outline, Color(0xFF616161)),
  unknown('unknown', '판별 불가', Icons.help_outline, Color(0xFF9E9E9E));

  const RecycleCategory(this.key, this.label, this.icon, this.color);

  /// AI 응답과 저장 데이터에서 쓰는 문자열 키.
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  /// 재활용 수거함으로 가는 분류인지 여부.
  bool get isRecyclable => switch (this) {
        RecycleCategory.general ||
        RecycleCategory.food ||
        RecycleCategory.unknown =>
          false,
        _ => true,
      };

  static RecycleCategory fromKey(String? key) {
    if (key == null) return RecycleCategory.unknown;
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    for (final c in RecycleCategory.values) {
      if (c.key == normalized) return c;
    }
    return RecycleCategory.unknown;
  }

  /// Gemini 응답 스키마에 넣을 허용 값 목록.
  static List<String> get allKeys =>
      RecycleCategory.values.map((c) => c.key).toList(growable: false);
}
