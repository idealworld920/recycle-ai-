import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/waste_group.dart';
import '../../screens/result_screen.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_badge.dart';
import 'history_record.dart';
import 'history_store.dart';

/// 분류 기록 탭. 상단 이번 달 요약, 아래 날짜별 목록.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final history = AppServices.of(context).history;
    final t = context.text;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) {
            final items = history.items;
            if (items.isEmpty) return _EmptyState(onGoHome: onGoHome);

            final now = DateTime.now();
            final groups = HistoryStore.groupByDay(items);

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('분류 기록', style: t.headlineSmall)),
                    TextButton(
                      onPressed: () => _confirmClear(context, history),
                      style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                      child: const Text('모두 삭제'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _MonthSummary(month: now, records: history.inMonth(now)),
                const SizedBox(height: AppSpacing.xl),
                for (final (day, records) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(_dayLabel(day, now), style: t.bodySmall),
                  ),
                  for (var i = 0; i < records.length; i++) ...[
                    Dismissible(
                      key: ValueKey(records[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        color: c.errorSoft,
                        child: Icon(Symbols.delete_rounded, color: c.error),
                      ),
                      onDismissed: (_) => history.remove(records[i].id),
                      child: _RecordRow(record: records[i]),
                    ),
                    if (i != records.length - 1) const Divider(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, HistoryStore history) async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록을 모두 지울까요?'),
        content: const Text('지운 기록은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: c.error),
            child: const Text('모두 삭제'),
          ),
        ],
      ),
    );
    if (ok == true) await history.clear();
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static String _dayLabel(DateTime day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    final w = _weekdays[day.weekday - 1];
    if (day.year == now.year) return '${day.month}월 ${day.day}일 ($w)';
    return '${day.year}년 ${day.month}월 ${day.day}일 ($w)';
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.month, required this.records});

  final DateTime month;
  final List<HistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final counts = HistoryStore.countByGroup(records);
    final total = records.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${month.month}월 분류', style: t.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$total', style: t.headlineSmall),
              const SizedBox(width: AppSpacing.xs),
              Text('건', style: t.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? ColoredBox(color: c.divider)
                  : Row(
                      children: [
                        for (final g in WasteGroup.values)
                          if (counts[g]! > 0) Expanded(flex: counts[g]!, child: ColoredBox(color: c.groupColor(g))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.xs,
            children: [
              for (final g in WasteGroup.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c.groupColor(g), shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${g.label} ${total == 0 ? 0 : (counts[g]! * 100 / total).round()}%',
                        style: t.bodySmall?.copyWith(color: c.textPrimary)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final time = '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () => context.pushPage(ResultScreen(result: record.toResult(), imageThumb: record.imageThumb)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            HistoryThumb(record: record, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      CategoryBadge.of(record.category),
                      const SizedBox(width: AppSpacing.sm),
                      Text(time, style: t.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 저장된 썸네일이 있으면 사진, 없으면 분류 아이콘.
class HistoryThumb extends StatelessWidget {
  const HistoryThumb({super.key, required this.record, this.size = 48});

  final HistoryRecord record;
  final double size;

  @override
  Widget build(BuildContext context) {
    final thumb = record.imageThumb;
    if (thumb == null || thumb.isEmpty) return CategoryIcon(category: record.category, size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Image.memory(
        base64Decode(thumb),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => CategoryIcon(category: record.category, size: size),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분류 기록', style: t.headlineSmall),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(Symbols.inbox_rounded, size: 44, color: c.textSecondary),
                const SizedBox(height: AppSpacing.base),
                Text('아직 기록이 없어요', style: t.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text('사진으로 분류하면 여기에 자동으로 쌓여요.', style: t.bodySmall),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(onPressed: onGoHome, child: const Text('분류하러 가기')),
        ],
      ),
    );
  }
}
