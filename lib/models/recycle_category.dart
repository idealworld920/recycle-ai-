import 'package:flutter/material.dart';

/// 한국 분리배출 기준에 맞춘 배출 분류.
enum RecycleCategory {
  pet('pet', '투명 페트병', '💧', Icons.water_drop_outlined, Color(0xFF38BDF8)),
  plastic('plastic', '플라스틱', '🧴', Icons.recycling, Color(0xFF3B82F6)),
  paper('paper', '종이', '📦', Icons.description_outlined, Color(0xFFB45309)),
  paperPack('paper_pack', '종이팩', '🥛', Icons.local_drink_outlined, Color(0xFFD97706)),
  can('can', '캔 · 고철', '🥫', Icons.hardware_outlined, Color(0xFF64748B)),
  glass('glass', '유리병', '🍾', Icons.wine_bar_outlined, Color(0xFF14B8A6)),
  vinyl('vinyl', '비닐', '🛍️', Icons.shopping_bag_outlined, Color(0xFF84CC16)),
  styrofoam('styrofoam', '스티로폼', '🧊', Icons.inventory_2_outlined, Color(0xFF94A3B8)),
  food('food', '음식물 쓰레기', '🍎', Icons.restaurant_outlined, Color(0xFFF97316)),
  hazardous('hazardous', '유해 폐기물', '🔋', Icons.warning_amber_outlined, Color(0xFFEF4444)),
  electronics('electronics', '폐가전', '📱', Icons.devices_other_outlined, Color(0xFF8B5CF6)),
  clothing('clothing', '의류', '👕', Icons.checkroom_outlined, Color(0xFFEC4899)),
  bulky('bulky', '대형 폐기물', '🛋️', Icons.weekend_outlined, Color(0xFF78350F)),
  general('general', '일반 쓰레기', '🗑️', Icons.delete_outline, Color(0xFF6B7280)),
  unknown('unknown', '판별 불가', '🤔', Icons.help_outline, Color(0xFF9CA3AF));

  const RecycleCategory(this.key, this.label, this.emoji, this.icon, this.color);

  /// AI 응답과 저장 데이터에서 쓰는 문자열 키.
  final String key;
  final String label;
  final String emoji;
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
