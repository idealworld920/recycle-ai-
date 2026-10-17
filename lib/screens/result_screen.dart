import 'dart:io';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recycling_guide.dart';
import '../features/tips/tip_card.dart';
import '../features/tips/tips_screen.dart';
import '../models/recycle_result.dart';
import '../widgets/category_badge.dart';
import 'guide_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result, this.isNew = false});

  final RecycleResult result;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cat = result.category;
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final guide = guideFor(cat);
    final tip = AppServices.of(context).tips.findForItem(result.itemName);

    return Scaffold(
      appBar: AppBar(title: const Text('판별 결과')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(aspectRatio: 4 / 3, child: Image.file(File(path), fit: BoxFit.cover)),
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(18)),
              child: Icon(cat.icon, size: 56, color: scheme.onSurface),
            ),
          const SizedBox(height: 24),
          CategoryBadge(category: cat, large: true),
          const SizedBox(height: 12),
          Text(result.itemName, style: text.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                cat.isRecyclable ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                size: 18,
                color: cat.isRecyclable ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(cat.isRecyclable ? '재활용 가능' : '재활용 불가', style: text.bodyMedium),
              const SizedBox(width: 12),
              Text('·', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              Text('AI 확신도 ${result.confidencePercent}%', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          if (result.confidencePercent < 60) ...[
            const SizedBox(height: 8),
            Text('확신도가 낮아요. 물건이 잘 보이게 다시 찍으면 더 정확해져요.', style: text.bodySmall?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 32),

          if (result.steps.isNotEmpty) ...[
            Text('이렇게 버려요', style: text.titleLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < result.steps.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(result.steps[i], style: text.bodyLarge))),
                  ],
                ),
              ),
              if (i != result.steps.length - 1) const Divider(),
            ],
            const SizedBox(height: 24),
          ],

          if (result.warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 20, color: scheme.onSurface),
                      const SizedBox(width: 8),
                      Text('주의할 점', style: text.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final w in result.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: text.bodyMedium),
                          Expanded(child: Text(w, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (result.tip.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 20, color: scheme.onSurface),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.tip, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          Text('품목 팁', style: text.titleLarge),
          const SizedBox(height: 10),
          if (tip != null)
            TipCard(tip: tip)
          else
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TipsScreen(initialQuery: result.itemName, showBackButton: true)),
              ),
              icon: const Icon(Icons.tips_and_updates_outlined, size: 20),
              label: const Text('팁 더 보기'),
            ),
          const SizedBox(height: 24),

          if (guide != null)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: guide))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('${cat.label} 가이드 전체 보기', style: text.titleSmall)),
                    Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('AI 판별 결과는 참고용이에요. 지자체마다 기준이 조금씩 달라요.', style: text.bodySmall),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          child: Text(isNew ? '다른 물건 판별하기' : '확인'),
        ),
      ),
    );
  }
}
