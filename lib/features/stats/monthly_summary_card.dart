import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/waste_group.dart';
import '../../widgets/app_card.dart';
import '../auth/locked_overlay.dart';
import 'stats_calculator.dart';

/// "이번 달 31개 분류 · 재활용 68%" + 지난달 대비 + 카테고리 가로 바.
class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.summary, required this.month, this.lockCompare = false, this.onConnect});

  final MonthlySummary summary;
  final DateTime month;

  /// 익명이면 "지난달 대비" 를 블러로 가린다.
  final bool lockCompare;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final rate = summary.recycleRate;
    final change = summary.changePoints;
    final up = change != null && change > 0;
    final maxCount = summary.counts.values.fold<int>(0, (m, v) => v > m ? v : m);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${month.month}월', style: t.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.total == 0 ? '아직 분류한 게 없어요' : '이번 달 ${summary.total}개 분류 · 재활용 $rate%',
            style: t.titleMedium,
          ),
          if (change != null || lockCompare) ...[
            const SizedBox(height: AppSpacing.xs),
            LockedOverlay(
              locked: lockCompare,
              message: '지난달 대비는 연결 후 볼 수 있어요',
              onConnect: onConnect ?? () {},
              child: Row(
              children: [
                Icon(
                  change == 0 ? Symbols.remove_rounded : (up ? Symbols.arrow_upward_rounded : Symbols.arrow_downward_rounded),
                  size: 16,
                  color: up ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  change == null
                      ? '지난달보다 0%p'
                      : change == 0
                          ? '지난달과 같아요'
                          : '지난달보다 ${change.abs()}%p ${up ? '올랐어요' : '내려갔어요'}',
                  style: t.bodySmall?.copyWith(color: up ? c.primary : c.textSecondary),
                ),
              ],
            ),
            ),
          ],
          if (summary.total > 0) ...[
            const SizedBox(height: AppSpacing.base),
            for (final g in WasteGroup.values) ...[
              _Bar(label: g.label, count: summary.counts[g]!, max: maxCount, color: c.groupColor(g)),
              if (g != WasteGroup.values.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.count, required this.max, required this.color});

  final String label;
  final int count;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final fraction = max == 0 ? 0.0 : count / max;
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: t.bodySmall)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  ColoredBox(color: c.divider, child: const SizedBox.expand()),
                  FractionallySizedBox(widthFactor: fraction, child: ColoredBox(color: color, child: const SizedBox.expand())),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 24, child: Text('$count', textAlign: TextAlign.end, style: t.bodySmall?.copyWith(color: c.textPrimary))),
      ],
    );
  }
}
