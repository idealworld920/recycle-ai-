import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../tips/tip_card.dart';
import 'quiz_model.dart';
import 'quiz_store.dart';

/// 이번 주 퀴즈 3문제. 틀리면 그 자리에서 팁 카드를 보여준다.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final String _weekId;
  late final List<QuizQuestion> _questions;
  final Map<String, int> _answers = {};
  int _index = 0;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final store = AppServices.of(context).quiz;
    _weekId = store.currentWeekId;
    _questions = store.repository.forWeek(_weekId);
    final prev = store.resultFor(_weekId);
    if (prev != null) {
      _answers.addAll(prev.answers);
      _done = true;
    }
  }

  int get _score => _questions.where((q) => _answers[q.id] == q.answer).length;

  Future<void> _choose(int choice) async {
    final q = _questions[_index];
    if (_answers.containsKey(q.id)) return;
    HapticFeedback.selectionClick();
    setState(() => _answers[q.id] = choice);
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    final services = AppServices.of(context);
    setState(() => _saving = true);
    final result = QuizResult(
      weekId: _weekId,
      score: _score,
      total: _questions.length,
      answers: Map.of(_answers),
      completedAt: DateTime.now(),
    );
    await services.quiz.save(result);
    // 맞힌 품목은 도감에.
    for (final q in _questions) {
      if (_answers[q.id] == q.answer) {
        final tip = services.tips.all.where((t) => t.id == q.tipId).firstOrNull;
        if (tip != null) await services.collection.collect(tip);
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    if (_questions.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('이번 주 퀴즈')), body: Center(child: Text('문제를 불러오지 못했어요', style: t.bodyMedium)));
    }
    if (_done) return _ResultView(questions: _questions, answers: _answers, score: _score);

    final q = _questions[_index];
    final picked = _answers[q.id];
    final answered = picked != null;
    final tips = AppServices.of(context).tips;
    final tip = tips.all.where((x) => x.id == q.tipId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('이번 주 퀴즈 ${_index + 1}/${_questions.length}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text(q.question, style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < q.choices.length; i++) ...[
            _Choice(
              label: q.choices[i],
              state: !answered
                  ? _ChoiceState.idle
                  : i == q.answer
                      ? _ChoiceState.correct
                      : (i == picked ? _ChoiceState.wrong : _ChoiceState.dim),
              onTap: answered ? null : () => _choose(i),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (answered) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBox(
              icon: picked == q.answer ? Symbols.check_circle_rounded : Symbols.info_rounded,
              child: Text(picked == q.answer ? '정답이에요. ${q.explanation}' : '아쉬워요. ${q.explanation}', style: t.bodyMedium),
            ),
            if (picked != q.answer && tip != null) ...[
              const SizedBox(height: AppSpacing.md),
              TipCard(tip: tip),
            ],
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
        child: FilledButton(
          onPressed: answered && !_saving ? _next : null,
          child: Text(_index < _questions.length - 1 ? '다음 문제' : (_saving ? '저장하는 중…' : '결과 보기')),
        ),
      ),
    );
  }
}

enum _ChoiceState { idle, correct, wrong, dim }

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.state, this.onTap});

  final String label;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final (bg, fg, icon) = switch (state) {
      _ChoiceState.idle => (c.surface, c.textPrimary, null),
      _ChoiceState.correct => (c.primarySoft, c.primary, Symbols.check_rounded),
      _ChoiceState.wrong => (c.surface, c.textSecondary, Symbols.close_rounded),
      _ChoiceState.dim => (c.surface, c.textDisabled, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.labelLarge?.copyWith(color: fg))),
              if (icon != null) Icon(icon, size: 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.questions, required this.answers, required this.score});

  final List<QuizQuestion> questions;
  final Map<String, int> answers;
  final int score;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final tips = AppServices.of(context).tips;
    return Scaffold(
      appBar: AppBar(title: const Text('이번 주 퀴즈')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('${questions.length}문제 중 $score개 맞혔어요', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(score == questions.length ? '맞힌 품목은 도감에 추가됐어요.' : '틀린 건 다음 주에 다시 나올 수 있어요. 맞힌 품목은 도감에 추가됐어요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          for (final q in questions) ...[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    answers[q.id] == q.answer ? Symbols.check_circle_rounded : Symbols.cancel_rounded,
                    size: 20,
                    color: answers[q.id] == q.answer ? c.primary : c.textSecondary,
                    fill: 1,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tips.all.where((x) => x.id == q.tipId).firstOrNull?.name ?? q.question, style: t.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text('정답: ${q.choices[q.answer]}', style: t.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
        child: FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('확인')),
      ),
    );
  }
}
