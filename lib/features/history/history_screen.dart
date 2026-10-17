import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../screens/result_screen.dart';
import '../../widgets/category_badge.dart';
import 'history_record.dart';
import 'history_store.dart';

/// 분류 기록 탭. 상단 이번 달 요약, 아래 날짜별 목록.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.onGoHome});

  /// 비어 있을 때 "분류하러 가기"를 누르면 홈 탭으로 보낸다.
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final history = AppServices.of(context).history;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) {
            final items = history.items;
            if (items.isEmpty) return _EmptyState(onGoHome: onGoHome);

            final now = DateTime.now();
            final monthItems = history.inMonth(now);
            final groups = HistoryStore.groupByDay(items);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('분류 기록', style: text.displaySmall)),
                    TextButton(
                      onPressed: () => _confirmClear(context, history),
                      child: Text('모두 삭제', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MonthSummary(month: now, records: monthItems),
                const SizedBox(height: 28),
                for (final (day, records) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(_dayLabel(day, now), style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  for (var i = 0; i < records.length; i++) ...[
                    Dismissible(
                      key: ValueKey(records[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: scheme.errorContainer,
                        child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
                      ),
                      onDismissed: (_) => history.remove(records[i].id),
                      child: _RecordRow(record: records[i]),
                    ),
                    if (i != records.length - 1) const Divider(),
                  ],
                  const SizedBox(height: 20),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, HistoryStore history) async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록을 모두 지울까요?'),
        content: const Text('지운 기록은 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('모두 삭제', style: TextStyle(color: scheme.error))),
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

  static const _colors = {
    HistoryGroup.recycle: Color(0xFF16A34A),
    HistoryGroup.general: Color(0xFF6B7280),
    HistoryGroup.food: Color(0xFFF97316),
    HistoryGroup.special: Color(0xFFE5484D),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final counts = HistoryStore.countByGroup(records);
    final total = records.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${month.month}월 분류', style: text.bodySmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$total', style: text.displaySmall),
              const SizedBox(width: 4),
              Text('건', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? ColoredBox(color: scheme.surfaceContainerHigh)
                  : Row(
                      children: [
                        for (final g in HistoryGroup.values)
                          if (counts[g]! > 0)
                            Expanded(flex: counts[g]!, child: ColoredBox(color: _colors[g]!)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final g in HistoryGroup.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _colors[g], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${g.label} ${total == 0 ? 0 : (counts[g]! * 100 / total).round()}%',
                      style: text.bodySmall?.copyWith(color: scheme.onSurface),
                    ),
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final time = '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: record.toResult(), imageThumb: record.imageThumb)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            HistoryThumb(record: record, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                  const SizedBox(height: 3),
                  Text('${record.category.label}  ·  $time', style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
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
      borderRadius: BorderRadius.circular(14),
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분류 기록', style: text.displaySmall),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44, color: scheme.onSurfaceVariant),
                const SizedBox(height: 14),
                Text('아직 기록이 없어요', style: text.titleMedium),
                const SizedBox(height: 6),
                Text('사진으로 분류하면 여기에 자동으로 쌓여요.', style: text.bodySmall),
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
