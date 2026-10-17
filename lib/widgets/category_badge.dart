import 'package:flutter/material.dart';

import '../models/recycle_category.dart';

/// 이모지 + 분류명 알약 배지.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.large = false});

  final RecycleCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fg = category.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: isDark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: TextStyle(fontSize: large ? 18 : 14)),
          SizedBox(width: large ? 8 : 5),
          Text(
            category.label,
            style: TextStyle(
              color: isDark ? Color.lerp(fg, Colors.white, 0.35) : Color.lerp(fg, Colors.black, 0.25),
              fontWeight: FontWeight.w700,
              fontSize: large ? 16 : 13,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 동그란 이모지 타일 (가이드/기록 썸네일 대용).
class EmojiTile extends StatelessWidget {
  const EmojiTile({super.key, required this.category, this.size = 52, this.radius = 16});

  final RecycleCategory category;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(category.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
