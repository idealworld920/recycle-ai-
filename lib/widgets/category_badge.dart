import 'package:flutter/material.dart';

import '../models/recycle_category.dart';

/// 분류 이름 알약. 회색 바탕에 분류 색 점 하나만 찍는다.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.large = false});

  final RecycleCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 7 : 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 8 : 6),
          Text(
            category.label,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 둥근 회색 바탕 위 라인 아이콘. 썸네일이 없을 때 쓴다.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 48, this.radius = 14});

  final RecycleCategory category;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(category.icon, size: size * 0.46, color: scheme.onSurface),
    );
  }
}
