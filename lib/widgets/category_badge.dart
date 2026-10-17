import 'package:flutter/material.dart';

import '../models/recycle_category.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.large = false});

  final RecycleCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fg = category.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: large ? 22 : 16, color: fg),
          SizedBox(width: large ? 8 : 4),
          Text(
            category.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: large ? 18 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
