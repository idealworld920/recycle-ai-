import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_badge.dart';
import '../places/region_guidance.dart';
import 'tip_model.dart';

/// 품목명 + 분류 뱃지 + 단계 목록 + 주의 박스.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip, this.showRegionGuidance = true});

  final Tip tip;

  /// 결과 화면처럼 바로 위에 지역 기준 박스를 이미 보여준 곳에서는 끈다 (같은 화면에 두 번 나오지 않게).
  final bool showRegionGuidance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tip.isRegionVariant && showRegionGuidance) ...[
            RegionGuidance(tip: tip, compact: true),
            const SizedBox(height: AppSpacing.md),
          ],
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
                  Icon(Symbols.warning_rounded, size: 18, color: c.warningText),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip.caution, style: t.bodySmall?.copyWith(color: c.warningText))),
                ],
              ),
            ),
          ],
          if (tip.hasLocalNote && !tip.isRegionVariant) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.location_on_rounded, size: 16, color: c.textSecondary),
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
