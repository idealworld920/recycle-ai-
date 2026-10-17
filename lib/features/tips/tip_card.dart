import 'package:flutter/material.dart';

import 'tip_model.dart';

/// 품목명 + 분류 뱃지 + 단계 목록 + 주의 박스.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tip.name, style: text.titleMedium)),
              const SizedBox(width: 8),
              TipCategoryBadge(category: tip.category),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tip.steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == tip.steps.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 1), child: Text(tip.steps[i], style: text.bodyMedium))),
                ],
              ),
            ),
          if (tip.hasCaution) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A2F0B) : const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: isDark ? const Color(0xFFFFD666) : const Color(0xFF8A6500)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip.caution,
                      style: text.bodySmall?.copyWith(color: isDark ? const Color(0xFFFFE9A8) : const Color(0xFF5C4300)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (tip.hasLocalNote) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(tip.localNote, style: text.bodySmall)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class TipCategoryBadge extends StatelessWidget {
  const TipCategoryBadge({super.key, required this.category});

  final TipCategory category;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.25 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Color.lerp(c, Colors.white, 0.4) : Color.lerp(c, Colors.black, 0.25),
        ),
      ),
    );
  }
}
