import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_services.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../data/recycling_guide.dart';
import '../features/feedback/feedback_sheet.dart';
import '../features/places/region_guidance.dart';
import '../features/share/share_service.dart';
import '../features/tips/tip_card.dart';
import '../features/tips/tips_screen.dart';
import '../models/recycle_result.dart';
import '../widgets/app_card.dart';
import '../widgets/result_card.dart';
import 'guide_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, this.isNew = false, this.imageBytes, this.imageThumb, this.toast, this.elapsed});

  final RecycleResult result;
  final bool isNew;

  /// 방금 찍은 원본 사진.
  final Uint8List? imageBytes;

  /// 기록에서 열 때 쓰는 작은 썸네일(base64).
  final String? imageThumb;

  /// 화면이 뜬 직후 보여줄 짧은 안내 (예: 도감 추가).
  final String? toast;

  /// 사진 선택부터 결과까지 걸린 시간. 3초를 넘겼으면 리뿅이가 한마디 한다.
  final Duration? elapsed;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    await ShareService.shareResult(context, result: result, photo: imageBytes);
    if (mounted) setState(() => _sharing = false);
  }

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
    final services = AppServices.of(context);
    final tip = services.tips.findForItem(result.itemName);
    final override = services.feedback.overrideFor(result.itemName);
    final showOverride = override != null && override != cat.group;
    final slow = (widget.elapsed ?? Duration.zero) > const Duration(seconds: 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('판별 결과'),
        actions: [
          IconButton(
            onPressed: _sharing ? null : _share,
            icon: const Icon(Symbols.share_rounded),
            tooltip: '공유',
          ),
        ],
      ),
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

          // 1~4. 품목명 → 뱃지 → 왜? → 배출 단계 (온보딩 목업과 같은 위젯)
          ResultCard(result: result, userAnswer: showOverride ? override : null, slow: slow),
          if (result.steps.isNotEmpty) const SizedBox(height: AppSpacing.xl) else const SizedBox(height: AppSpacing.xxl),

          // 5. 지역 기준: 검증된 우리 동네 노트(파랑) 또는 "지자체별로 다를 수 있어요"(노랑)
          if (tip != null && (tip.isRegionVariant || tip.hasLocalNote)) ...[
            RegionGuidance(tip: tip),
            const SizedBox(height: AppSpacing.md),
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
            TipCard(tip: tip, showRegionGuidance: false)
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
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs), foregroundColor: c.textSecondary),
              onPressed: () => showFeedbackSheet(context, result: result, imageBytes: imageBytes),
              child: const Text('결과가 틀렸나요?'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sharing ? null : _share,
                icon: const Icon(Symbols.share_rounded, size: 20),
                label: Text(_sharing ? '만드는 중…' : '공유하기', maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Text(isNew ? '다른 물건 판별하기' : '확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
