import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'waste_group.dart';

/// 한국 분리배출 기준에 맞춘 배출 분류.
enum RecycleCategory {
  pet('pet', '투명 페트병', Symbols.water_drop_rounded),
  plastic('plastic', '플라스틱', Symbols.recycling_rounded),
  paper('paper', '종이', Symbols.description_rounded),
  paperPack('paper_pack', '종이팩', Symbols.local_drink_rounded),
  can('can', '캔 · 고철', Symbols.hardware_rounded),
  glass('glass', '유리병', Symbols.wine_bar_rounded),
  vinyl('vinyl', '비닐', Symbols.shopping_bag_rounded),
  styrofoam('styrofoam', '스티로폼', Symbols.inventory_2_rounded),
  food('food', '음식물 쓰레기', Symbols.restaurant_rounded),
  hazardous('hazardous', '유해 폐기물', Symbols.warning_rounded),
  electronics('electronics', '폐가전', Symbols.devices_other_rounded),
  clothing('clothing', '의류', Symbols.checkroom_rounded),
  bulky('bulky', '대형 폐기물', Symbols.weekend_rounded),
  general('general', '일반 쓰레기', Symbols.delete_rounded),
  unknown('unknown', '판별 불가', Symbols.help_rounded);

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
