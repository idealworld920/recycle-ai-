import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../data/recycling_guide.dart';
import '../features/tips/tip_card.dart';
import '../features/tips/tips_screen.dart';
import '../models/recycle_result.dart';
import '../widgets/app_card.dart';
import '../widgets/category_badge.dart';
import 'guide_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, this.isNew = false, this.imageBytes, this.imageThumb, this.toast});

  final RecycleResult result;
  final bool isNew;

  /// 방금 찍은 원본 사진.
  final Uint8List? imageBytes;

  /// 기록에서 열 때 쓰는 작은 썸네일(base64).
  final String? imageThumb;

  /// 화면이 뜬 직후 보여줄 짧은 안내 (예: 도감 추가).
  final String? toast;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  RecycleResult get result => widget.result;
  bool get isNew => widget.isNew;
  Uint8List? get imageBytes => widget.imageBytes;
  String? get imageThumb => widget.imageThumb;

  @override
  void initState() {
    super.initState();
    final toast = widget.toast;
    if (toast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast), duration: const Duration(seconds: 2)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final cat = result.category;
    final guide = guideFor(cat);
    final tip = AppServices.of(context).tips.findForItem(result.itemName);

    return Scaffold(
      appBar: AppBar(title: const Text('판별 결과')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(aspectRatio: 4 / 3, child: Image.memory(imageBytes!, fit: BoxFit.cover)),
            )
          else if (imageThumb != null && imageThumb!.isNotEmpty)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Image.memory(base64Decode(imageThumb!), width: 96, height: 96, fit: BoxFit.cover),
                ),
              ],
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Icon(cat.icon, size: 48, color: c.textPrimary),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(children: [CategoryBadge.of(cat, large: true)]),
          const SizedBox(height: AppSpacing.md),
          Text(result.itemName, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                cat.isRecyclable ? Symbols.check_circle_rounded : Symbols.do_not_disturb_on_rounded,
                size: 18,
                color: cat.isRecyclable ? c.primary : c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(cat.isRecyclable ? '재활용 가능' : '재활용 불가', style: t.bodyMedium),
              const SizedBox(width: AppSpacing.md),
              Text('AI 확신도 ${result.confidencePercent}%', style: t.bodySmall),
            ],
          ),
          if (result.confidencePercent < 60) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('확신도가 낮아요. 물건이 잘 보이게 다시 찍으면 더 정확해져요.', style: t.bodySmall?.copyWith(color: c.error)),
          ],
          const SizedBox(height: AppSpacing.xxl),

          if (result.steps.isNotEmpty) ...[
            Text('이렇게 버려요', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < result.steps.length; i++) ...[
              _Step(index: i + 1, text: result.steps[i]),
              if (i != result.steps.length - 1) const Divider(),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],

          if (result.warnings.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.error_rounded, size: 20, color: c.textPrimary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('주의할 점', style: t.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final w in result.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text('•  $w', style: t.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (result.tip.isNotEmpty) InfoBox(icon: Symbols.lightbulb_rounded, child: Text(result.tip, style: t.bodyMedium)),
          const SizedBox(height: AppSpacing.xl),

          Text('품목 팁', style: t.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (tip != null)
            TipCard(tip: tip)
          else
            OutlinedButton.icon(
              onPressed: () => context.pushPage(TipsScreen(initialQuery: result.itemName, showBackButton: true)),
              icon: const Icon(Symbols.lightbulb_rounded, size: 20),
              label: const Text('팁 더 보기'),
            ),
          const SizedBox(height: AppSpacing.xl),

          if (guide != null)
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onTap: () => showGuideDetailSheet(context, guide),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(child: Text('${cat.label} 가이드 전체 보기', style: t.titleSmall)),
                    Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('AI 판별 결과는 참고용이에요. 지자체마다 기준이 조금씩 달라요.', style: t.bodySmall),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
        child: FilledButton(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          child: Text(isNew ? '다른 물건 판별하기' : '확인'),
        ),
      ),
    );
  }
}

/// 번호 + 문장 한 줄. 결과·가이드에서 같이 쓴다.
class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepNumber(index: index),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(text, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)))),
        ],
      ),
    );
  }
}

class StepNumber extends StatelessWidget {
  const StepNumber({super.key, required this.index, this.size = 24});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
      child: Text('$index', style: context.text.labelLarge?.copyWith(fontSize: size * 0.5, color: c.onInk, height: 1)),
    );
  }
}
