import 'package:flutter/material.dart';

import 'waste_group.dart';

/// 한국 분리배출 기준에 맞춘 배출 분류.
enum RecycleCategory {
  pet('pet', '투명 페트병', Icons.water_drop_outlined),
  plastic('plastic', '플라스틱', Icons.recycling),
  paper('paper', '종이', Icons.description_outlined),
  paperPack('paper_pack', '종이팩', Icons.local_drink_outlined),
  can('can', '캔 · 고철', Icons.hardware_outlined),
  glass('glass', '유리병', Icons.wine_bar_outlined),
  vinyl('vinyl', '비닐', Icons.shopping_bag_outlined),
  styrofoam('styrofoam', '스티로폼', Icons.inventory_2_outlined),
  food('food', '음식물 쓰레기', Icons.restaurant_outlined),
  hazardous('hazardous', '유해 폐기물', Icons.warning_amber_outlined),
  electronics('electronics', '폐가전', Icons.devices_other_outlined),
  clothing('clothing', '의류', Icons.checkroom_outlined),
  bulky('bulky', '대형 폐기물', Icons.weekend_outlined),
  general('general', '일반 쓰레기', Icons.delete_outline),
  unknown('unknown', '판별 불가', Icons.help_outline);

  const RecycleCategory(this.key, this.label, this.icon);

  /// AI 응답과 저장 데이터에서 쓰는 문자열 키.
  final String key;
  final String label;
  final IconData icon;

  /// 뱃지·통계용 4분류.
  WasteGroup get group => switch (this) {
        RecycleCategory.food => WasteGroup.food,
        RecycleCategory.hazardous || RecycleCategory.electronics || RecycleCategory.bulky => WasteGroup.special,
        RecycleCategory.general || RecycleCategory.unknown => WasteGroup.general,
        _ => WasteGroup.recycle,
      };

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
