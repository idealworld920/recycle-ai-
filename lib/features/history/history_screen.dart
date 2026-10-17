import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/result_screen.dart';
import '../../widgets/category_badge.dart';
import '../auth/auth_store.dart';
import '../auth/link_banner.dart';
import '../auth/link_flows.dart';
import '../auth/locked_overlay.dart';
import '../stats/collection_sheet.dart';
import '../stats/monthly_summary_card.dart';
import '../stats/stats_calculator.dart';
import '../stats/streak_row.dart';
import 'history_record.dart';
import 'history_store.dart';

/// 분류 기록 탭. 상단 이번 달 요약, 아래 날짜별 목록.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final history = services.history;
    final schedule = services.schedule;
    final auth = services.auth;
    final settings = services.settings;
    final t = context.text;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([history, schedule, auth]),
          builder: (context, _) {
            final items = history.items;
            if (items.isEmpty) return _EmptyState(onGoHome: onGoHome);

            final now = DateTime.now();
            final anonymous = auth.isAnonymous;
            // 익명이면 최근 30일만 목록에. 나머지는 저장만 되고 잠금 카드로 안내.
            final cutoff = now.subtract(const Duration(days: 30));
            final visible = anonymous ? items.where((r) => r.date.isAfter(cutoff)).toList() : items;
            final hiddenCount = items.length - visible.length;
            final groups = HistoryStore.groupByDay(visible);
            void connect() => connectGoogle(context);

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
                if (anonymous && settings.daysSinceInstall >= 30)
                  const LinkBanner(
                    promptKey: AuthStore.keyHistory30,
                    title: '설치한 지 30일, 기록이 꽤 쌓였어요',
                    body: '구글로 연결해 두면 기기를 바꾸거나 앱을 지워도 기록이 그대로예요.',
                  ),
                MonthlySummaryCard(
                  summary: StatsCalculator.monthlySummary(items, now),
                  month: now,
                  lockCompare: anonymous,
                  onConnect: connect,
                ),
                const SizedBox(height: AppSpacing.sm),
                StreakRow(streak: schedule.streak(now), lockHistory: anonymous, onConnect: connect),
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
                if (hiddenCount > 0) ...[
                  LockedOverlay(message: '이전 기록 $hiddenCount건이 보관 중이에요 · 구글로 연결하면 열려요', onConnect: connect),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const CollectionCard(),
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
