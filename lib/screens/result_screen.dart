import 'dart:io';

import 'package:flutter/material.dart';

import '../data/recycling_guide.dart';
import '../models/recycle_result.dart';
import '../widgets/category_badge.dart';
import 'guide_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final RecycleResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cat = result.category;
    final path = result.imagePath;
    final hasImage = path != null && File(path).existsSync();
    final guide = guideFor(cat);

    return Scaffold(
      appBar: AppBar(title: const Text('판별 결과')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 16),
          Text(result.itemName, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              CategoryBadge(category: cat, large: true),
              const Spacer(),
              Icon(
                cat.isRecyclable ? Icons.check_circle : Icons.cancel,
                color: cat.isRecyclable ? Colors.green : scheme.outline,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(cat.isRecyclable ? '재활용 가능' : '재활용 불가',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          _ConfidenceBar(value: result.confidence, color: cat.color),
          const SizedBox(height: 24),
          if (result.steps.isNotEmpty) ...[
            Text('이렇게 버리세요', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var i = 0; i < result.steps.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == result.steps.length - 1 ? 0 : 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: cat.color,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(result.steps[i], style: text.bodyLarge),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (result.warnings.isNotEmpty) ...[
            Card(
              color: const Color(0xFFFFF3E0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
                        SizedBox(width: 8),
                        Text('주의하세요',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final w in result.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $w', style: const TextStyle(color: Color(0xFF4E342E))),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (result.tip.isNotEmpty)
            Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(result.tip)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (guide != null)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GuideDetailScreen(entry: guide)),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text('${cat.label} 전체 가이드 보기'),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('다른 물건 판별하기'),
          ),
          const SizedBox(height: 12),
          Text(
            'AI 판별 결과는 참고용이에요. 지자체마다 기준이 조금씩 다를 수 있어요.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI 확신도', style: Theme.of(context).textTheme.labelLarge),
            Text('$percent%', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        if (percent < 60)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '확신도가 낮아요. 물건이 잘 보이게 다시 찍으면 더 정확해져요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
