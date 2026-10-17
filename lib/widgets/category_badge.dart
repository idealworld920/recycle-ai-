import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/recycle_category.dart';
import '../models/waste_group.dart';

/// 분류 뱃지: 그룹 색 10% 배경에 진한 글자.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.label, required this.group, this.large = false});

  CategoryBadge.of(RecycleCategory category, {super.key, this.large = false})
      : label = category.label,
        group = category.group;

  final String label;
  final WasteGroup group;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? AppSpacing.md : AppSpacing.sm, vertical: large ? AppSpacing.sm : AppSpacing.xs),
      decoration: BoxDecoration(color: c.groupSoft(group), borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Text(
        label,
        style: context.text.labelLarge?.copyWith(fontSize: large ? 14 : 12.5, color: c.groupColor(group)),
      ),
    );
  }
}

/// 둥근 surface 바탕 위 아이콘. 썸네일이 없을 때 쓴다.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 48, this.radius = 14});

  final RecycleCategory category;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(radius)),
      child: Icon(category.icon, size: size * 0.46, color: c.textPrimary),
    );
  }
}
