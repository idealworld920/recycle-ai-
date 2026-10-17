import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_badge.dart';
import 'tip_model.dart';

/// 품목명 + 분류 뱃지 + 단계 목록 + 주의 박스.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tip.name, style: t.titleSmall)),
              const SizedBox(width: AppSpacing.sm),
              CategoryBadge(label: tip.category.label, group: tip.category.group),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < tip.steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == tip.steps.length - 1 ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: t.labelLarge?.copyWith(fontSize: 12, color: c.onInk, height: 1)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip.steps[i], style: t.bodyMedium)),
                ],
              ),
            ),
          if (tip.hasCaution) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AppSpacing.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: c.warningText),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip.caution, style: t.bodySmall?.copyWith(color: c.warningText))),
                ],
              ),
            ),
          ],
          if (tip.hasLocalNote) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 16, color: c.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(tip.localNote, style: t.bodySmall)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
