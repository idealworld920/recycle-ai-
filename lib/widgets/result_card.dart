import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/mascot.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/recycle_result.dart';
import '../models/waste_group.dart';
import 'category_badge.dart';

/// 판별 결과의 핵심 블록: 품목명 → 분류 뱃지 → "왜?" 한 줄 → 배출 단계.
///
/// 결과 화면이 그대로 쓰고, 온보딩 1페이지는 샘플 데이터로 같은 위젯을 목업처럼 보여준다.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    this.userAnswer,
    this.slow = false,
    this.showConfidence = true,
  });

  final RecycleResult result;

  /// 사용자가 "결과가 틀렸나요?" 로 고친 답. AI 분류와 다를 때만 넘긴다.
  final WasteGroup? userAnswer;

  /// 결과까지 3초를 넘겼을 때 리뿅이 한마디.
  final bool slow;

  /// 확신도 표시 (목업에서는 숨긴다).
  final bool showConfidence;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final cat = result.category;
    final override = userAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 품목명
        Text(result.itemName, style: t.headlineSmall),
        const SizedBox(height: AppSpacing.md),

        // 2. 카테고리 뱃지 (+ 내가 고친 답이 있으면 그걸 먼저)
        if (override != null)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CategoryBadge(label: '${override.label} · 내가 고친 답', group: override, large: true),
              Text('AI 분류: ${cat.label}', style: t.bodySmall),
            ],
          )
        else
          Row(
            children: [
              CategoryBadge.of(cat, large: true),
              const SizedBox(width: AppSpacing.md),
              Icon(
                cat.isRecyclable ? Symbols.check_circle_rounded : Symbols.do_not_disturb_on_rounded,
                size: 18,
                color: cat.isRecyclable ? c.primary : c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(cat.isRecyclable ? '재활용 가능' : '재활용 불가', style: t.bodyMedium),
              if (showConfidence) ...[
                const Spacer(),
                Text('확신도 ${result.confidencePercent}%', style: t.bodySmall),
              ],
            ],
          ),
        if (showConfidence && result.confidencePercent < 60) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('확신도가 낮아요. 물건이 잘 보이게 다시 찍으면 더 정확해져요.', style: t.bodySmall?.copyWith(color: c.error)),
        ],

        // 3. 왜?
        if (result.reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.base),
          ResultReason(text: result.reason),
        ],
        if (slow) ...[
          const SizedBox(height: AppSpacing.md),
          const MascotSay(mascot: Mascot.cheer, text: '기다려줘서 고마워뿅! 꼼꼼히 봤어뿅.', size: 56),
        ],

        // 4. 배출 방법
        if (result.steps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text('이렇게 버려요', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < result.steps.length; i++) ...[
            ResultStep(index: i + 1, text: result.steps[i]),
            if (i != result.steps.length - 1) const Divider(),
          ],
        ],
      ],
    );
  }
}

/// "왜?" 한 줄. 분류 근거를 짧게.
class ResultReason extends StatelessWidget {
  const ResultReason({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(AppRadius.chip)),
          child: Text('왜?', style: t.labelLarge?.copyWith(color: c.onInk, fontSize: 12.5)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: t.bodyMedium?.copyWith(color: c.textPrimary))),
      ],
    );
  }
}

/// 번호 + 문장 한 줄. 결과·가이드에서 같이 쓴다.
class ResultStep extends StatelessWidget {
  const ResultStep({super.key, required this.index, required this.text});

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
