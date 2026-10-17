import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'quiz_screen.dart';

/// 홈 하단 "이번 주 퀴즈" 진입 카드.
class QuizCard extends StatelessWidget {
  const QuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).quiz;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final result = store.thisWeek;
        return AppCard(
          onTap: () => context.pushPage(const QuizScreen()),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Icon(Symbols.quiz_rounded, size: 24, color: result == null ? c.textPrimary : c.primary, fill: result == null ? 0 : 1),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('헷갈리는 쓰레기 퀴즈', style: t.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      result == null ? '이번 주 3문제, 1분이면 돼요' : '이번 주 ${result.score}/${result.total} 맞혔어요',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        );
      },
    );
  }
}
