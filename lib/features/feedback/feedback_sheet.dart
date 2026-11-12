import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recycle_result.dart';
import '../../models/waste_group.dart';

/// "결과가 틀렸나요?" 바텀시트. 정답 4분류 + 선택 메모 → 제출 → 리뿅이 인사.
Future<void> showFeedbackSheet(BuildContext context, {required RecycleResult result, Uint8List? imageBytes}) {
  return showAppSheet<void>(
    context,
    title: '결과가 틀렸나요?',
    initialSize: 0.62,
    maxSize: 0.9,
    builder: (ctx, controller) => _FeedbackBody(result: result, imageBytes: imageBytes, controller: controller),
  );
}

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody({required this.result, required this.imageBytes, required this.controller});

  final RecycleResult result;
  final Uint8List? imageBytes;
  final ScrollController controller;

  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  WasteGroup? _answer;
  final _memo = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final answer = _answer;
    if (answer == null || _busy) return;
    setState(() => _busy = true);
    final store = AppServices.of(context).feedback;
    await store.submit(result: widget.result, userAnswer: answer, memo: _memo.text, imageBytes: widget.imageBytes);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final aiGroup = widget.result.category.group;

    if (_done) {
      return ListView(
        controller: widget.controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        children: const [
          Center(child: MascotSay(mascot: Mascot.happy, text: '고마워뿅! 더 똑똑해질게뿅!', size: 88)),
        ],
      );
    }

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Text('AI 는 "${widget.result.itemName}" 을(를) ${aiGroup.label}(으)로 봤어요. 실제로는 어디에 버리나요?', style: t.bodyMedium),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final g in WasteGroup.values)
              ChoiceChip(
                label: Text(g == aiGroup ? '${g.label} (AI 답)' : g.label),
                selected: _answer == g,
                onSelected: (_) => setState(() => _answer = g),
                selectedColor: c.groupSoft(g),
                labelStyle: t.labelLarge?.copyWith(color: _answer == g ? c.groupColor(g) : c.textPrimary),
                side: BorderSide(color: _answer == g ? c.groupColor(g) : c.divider),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _memo,
          maxLength: 120,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '메모 (선택) 예: 색깔 있는 페트병이었어요',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _answer == null || _busy ? null : _submit,
          icon: const Icon(Symbols.send_rounded, size: 20),
          label: Text(_busy ? '보내는 중…' : '보내기'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('보내주신 정답은 같은 품목을 다시 분류할 때 먼저 보여드리고, AI 개선에만 써요. 사진은 보내지 않아요.', style: t.bodySmall),
      ],
    );
  }
}
