import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/result_screen.dart';
import '../../widgets/category_badge.dart';
import '../auth/auth_store.dart';
import '../calendar/calendar_screen.dart';
import '../auth/link_banner.dart';
import '../auth/link_flows.dart';
import '../auth/locked_overlay.dart';
import '../report/report_card.dart';
import '../stats/collection_sheet.dart';
import '../stats/monthly_summary_card.dart';
import '../stats/stats_calculator.dart';
import '../stats/streak_row.dart';
import 'delete_records.dart';
import 'history_record.dart';
import 'history_store.dart';
import '../../core/analytics.dart';

/// 분류 기록 탭. 상단 세그먼트 [기록 | 캘린더]. 기록: 이번 달 요약 + 날짜별 목록. 캘린더: 월간 뷰.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _calendar = false;

  /// 선택 모드. 길게 누르거나 [선택] 으로 들어오고, 뒤로가기·[취소]·삭제 완료로 나간다.
  bool _selecting = false;
  final Set<String> _selected = {};

  void _enterSelection([String? firstId]) => setState(() {
    _selecting = true;
    _selected.clear();
    if (firstId != null) _selected.add(firstId);
  });

  void _exitSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  /// 날짜 헤더 탭: 그날 항목이 모두 선택돼 있으면 해제, 아니면 전부 선택.
  void _toggleDay(List<HistoryRecord> records) => setState(() {
    final ids = records.map((r) => r.id);
    if (ids.every(_selected.contains)) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
  });

  void _toggleAll(List<HistoryRecord> visible) => setState(() {
    if (_selected.length == visible.length) {
      _selected.clear();
    } else {
      _selected
        ..clear()
        ..addAll(visible.map((r) => r.id));
    }
  });

  Future<void> _deleteSelected() async {
    final ok = await RecordDeleter.confirmAndDelete(context, _selected.toList());
    if (ok && mounted) _exitSelection();
  }

  VoidCallback? get onGoHome => widget.onGoHome;

  Widget _segment(BuildContext context) => SegmentedButton<bool>(
    segments: const [
      ButtonSegment(value: false, label: Text('기록'), icon: Icon(Symbols.history_rounded, size: 18)),
      ButtonSegment(value: true, label: Text('캘린더'), icon: Icon(Symbols.calendar_month_rounded, size: 18)),
    ],
    selected: {_calendar},
    showSelectedIcon: false,
    onSelectionChanged: (s) => setState(() => _calendar = s.first),
  );

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    if (_calendar) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            children: [
              Row(
                children: [Expanded(child: Text('캘린더', style: context.text.headlineSmall))],
              ),
              const SizedBox(height: AppSpacing.md),
              _segment(context),
              const SizedBox(height: AppSpacing.base),
              const CalendarView(),
            ],
          ),
        ),
      );
    }
    final history = services.history;
    final schedule = services.schedule;
    final auth = services.auth;
    final settings = services.settings;
    final t = context.text;
    final c = context.colors;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) _exitSelection();
      },
      child: Scaffold(
        bottomNavigationBar: _selecting
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: FilledButton(onPressed: _selected.isEmpty ? null : _deleteSelected, child: Text('${_selected.length}개 삭제')),
                ),
              )
            : null,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([history, schedule, auth]),
            builder: (context, _) {
              final items = history.items;
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    _segment(context),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: _EmptyState(onGoHome: onGoHome),
                    ),
                  ],
                );
              }

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
                  if (_selecting)
                    Row(
                      children: [
                        TextButton(
                          onPressed: _exitSelection,
                          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                          child: const Text('취소'),
                        ),
                        Expanded(
                          child: Text('${_selected.length}개 선택', textAlign: TextAlign.center, style: t.titleMedium),
                        ),
                        TextButton(onPressed: () => _toggleAll(visible), child: Text(_selected.length == visible.length ? '전체 해제' : '전체 선택')),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('분류 기록', style: t.headlineSmall)),
                        TextButton(
                          onPressed: () => _enterSelection(),
                          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                          child: const Text('선택'),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _segment(context),
                  const SizedBox(height: AppSpacing.base),
                  if (anonymous && settings.daysSinceInstall >= 30)
                    const LinkBanner(promptKey: AuthStore.keyHistory30, title: '설치한 지 30일, 기록이 꽤 쌓였어요', body: '구글로 연결해 두면 기기를 바꾸거나 앱을 지워도 기록이 그대로예요.'),
                  ReportCard(now: now),
                  MonthlySummaryCard(summary: StatsCalculator.monthlySummary(items, now), month: now, lockCompare: anonymous, onConnect: connect),
                  const SizedBox(height: AppSpacing.sm),
                  StreakRow(streak: schedule.streak(now), lockHistory: anonymous, onConnect: connect),
                  const SizedBox(height: AppSpacing.xl),
                  for (final (day, records) in groups) ...[
                    InkWell(
                      onTap: _selecting ? () => _toggleDay(records) : null,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(child: Text(_dayLabel(day, now), style: t.bodySmall)),
                            if (_selecting)
                              Text(records.every((r) => _selected.contains(r.id)) ? '선택 해제' : '모두 선택', style: t.bodySmall?.copyWith(color: c.primary)),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < records.length; i++) ...[
                      if (_selecting)
                        _RecordRow(record: records[i], selecting: true, selected: _selected.contains(records[i].id), onTap: () => _toggle(records[i].id))
                      else
                        Dismissible(
                          key: ValueKey(records[i].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: AppSpacing.lg),
                            color: c.errorSoft,
                            child: Icon(Symbols.delete_rounded, color: c.error),
                          ),
                          confirmDismiss: (_) => RecordDeleter.confirm(context, 1),
                          onDismissed: (_) async {
                            final n = await RecordDeleter.delete(services, [records[i].id]);
                            Analytics.log('history_delete', {'count': n, 'from': 'select'});
                            if (context.mounted && n > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('기록 $n개를 삭제했어요')));
                            }
                          },
                          child: _RecordRow(
                            record: records[i],
                            onTap: () =>
                                context.pushPage(ResultScreen(result: records[i].toResult(), imageThumb: records[i].imageThumb, recordId: records[i].id)),
                            onLongPress: () => _enterSelection(records[i].id),
                          ),
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
      ),
    );
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
  const _RecordRow({required this.record, required this.onTap, this.onLongPress, this.selecting = false, this.selected = false});

  final HistoryRecord record;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final time = '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            if (selecting) ...[
              Semantics(
                checked: selected,
                label: '선택',
                child: _CircleCheck(selected: selected),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
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
            if (!selecting) Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 선택 모드의 원형 체크박스. 선택되면 primary(#2563EB) 로 채운다.
class _CircleCheck extends StatelessWidget {
  const _CircleCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.primary : Colors.transparent,
        border: Border.all(color: selected ? c.primary : c.divider, width: 1.5),
      ),
      child: selected ? Icon(Symbols.check_rounded, size: 16, color: c.onInk, weight: 700) : null,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분류 기록', style: t.headlineSmall),
          const Spacer(),
          const MascotEmpty(mascot: Mascot.idle, text: '아직 기록이 없뿅. 사진으로 분류하면 여기에 쌓이뿅!'),
          const Spacer(),
          FilledButton(onPressed: onGoHome, child: const Text('분류하러 가기')),
        ],
      ),
    );
  }
}
