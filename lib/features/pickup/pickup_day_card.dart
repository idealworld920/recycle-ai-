import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// 홈 상단 수거일 카드. 지역 설정·수거일 알림은 다음 단계에서 채운다.
class PickupDayCard extends StatelessWidget {
  const PickupDayCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 24, color: c.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('우리 동네 수거일', style: t.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text('지역을 설정하면 수거일을 알려드려요', style: t.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textDisabled),
        ],
      ),
    );
  }
}
