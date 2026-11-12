import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'report_calculator.dart';
import 'report_screen.dart';

/// 기록 탭 상단 "지난달 리포트" 카드. 그 달에 분류가 1건 이상일 때만 보인다.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final history = AppServices.of(context).history;
    final last = DateTime(now.year, now.month - 1, 1);
    final count = history.items.where((r) => ReportCalculator.sameMonth(r.date, last)).length;
    if (count == 0) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => context.pushPage(ReportScreen(month: last)),
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Icon(Symbols.bar_chart_rounded, color: c.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${last.month}월 리포트가 나왔어요', style: t.titleSmall),
                  Text('분류 $count개 · 재활용률과 탄소 절감까지', style: t.bodySmall),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
