import 'dart:io';

import 'package:flutter/material.dart';

import '../data/recycling_guide.dart';
import '../models/recycle_result.dart';
import '../theme/app_theme.dart';
import '../widgets/category_badge.dart';
import 'guide_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result, this.isNew = false});

  final RecycleResult result;

  /// 방금 판별한 결과면 점수 적립 배지를 보여준다.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cat = result.category;
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final guide = guideFor(cat);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('판별 결과'),
        actions: [
          if (isNew && cat.isRecyclable)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: const Text('+10 🌍'),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onLime),
                backgroundColor: AppColors.lime,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // 헤더 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(AppShape.card + 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.itemName, style: text.headlineSmall),
                          const SizedBox(height: 10),
                          CategoryBadge(category: cat, large: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(width: 84, height: 84, child: Image.file(File(path), fit: BoxFit.cover)),
                      )
                    else
                      Text(cat.emoji, style: const TextStyle(fontSize: 56)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Pill(
                      icon: cat.isRecyclable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      iconColor: cat.isRecyclable ? AppColors.green : scheme.onSurfaceVariant,
                      label: cat.isRecyclable ? '재활용 가능' : '재활용 불가',
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: cat.color,
                      label: 'AI 확신 ${result.confidencePercent}%',
                    ),
                  ],
                ),
                if (result.confidencePercent < 60) ...[
                  const SizedBox(height: 10),
                  Text(
                    '확신도가 낮아요. 물건이 잘 보이게 다시 찍으면 더 정확해져요.',
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (result.steps.isNotEmpty) ...[
            Text('이렇게 버려요 👇', style: text.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < result.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                          child: Text('${i + 1}',
                              style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(result.steps[i], style: text.bodyLarge),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          if (result.warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB020).withValues(alpha: isDark ? 0.18 : 0.16),
                borderRadius: BorderRadius.circular(AppShape.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('잠깐! 이건 조심 ⚠️', style: text.titleMedium),
                  const SizedBox(height: 8),
                  for (final w in result.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $w', style: text.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (result.tip.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppShape.card),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.tip, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          if (guide != null)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: guide))),
              icon: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
              label: Text('${cat.label} 가이드 전체 보기'),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Text('📸', style: TextStyle(fontSize: 20)),
            label: const Text('다른 것도 찍어볼래'),
          ),
          const SizedBox(height: 14),
          Text(
            'AI 판별은 참고용이에요. 지자체마다 기준이 조금씩 달라요.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.iconColor, required this.label});

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}
