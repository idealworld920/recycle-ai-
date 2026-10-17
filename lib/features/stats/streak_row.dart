import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'stats_calculator.dart';

/// "연속 n주 수거일 체크" + 주별 점 12개. 끊겨도 아무 말 안 한다.
class StreakRow extends StatelessWidget {
  const StreakRow({super.key, required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(streak.weeks > 0 ? '🔥 연속 ${streak.weeks}주 수거일 체크' : '수거일 체크', style: t.titleSmall)),
              Text('최근 12주', style: t.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final dot in streak.dots) ...[
                Expanded(
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot.success ? c.primary : (dot.isCurrent ? c.background : c.divider),
                        border: dot.isCurrent && !dot.success ? Border.all(color: c.primary, width: 1.5) : null,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 홈 카드 하단용 한 줄.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context) {
    if (weeks <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text('🔥 $weeks주 연속', style: context.text.bodySmall?.copyWith(color: context.colors.primary)),
    );
  }
}
