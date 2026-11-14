import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../history/history_record.dart';
import '../places/external_links.dart';
import '../premium/premium_gate.dart';
import '../schedule/pickup_schedule.dart';
import 'calendar_event.dart';

/// 기록 탭 [캘린더] 세그먼트. 월간 그리드 + 날짜 패널. 스와이프로 월 이동.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  static const _origin = 2024 * 12; // 페이지 index = 연*12 + (월-1) - _origin
  late final PageController _pages;
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _pages = PageController(initialPage: _index(_month));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  static int _index(DateTime m) => m.year * 12 + (m.month - 1) - _origin;
  static DateTime _monthAt(int index) => DateTime((index + _origin) ~/ 12, (index + _origin) % 12 + 1);

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final t = context.text;
    return ListenableBuilder(
      listenable: Listenable.merge([services.schedule, services.events, services.history, services.premium]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => _pages.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut), icon: const Icon(Symbols.chevron_left_rounded)),
              Expanded(child: Text('${_month.year}년 ${_month.month}월', style: t.titleMedium, textAlign: TextAlign.center)),
              IconButton(onPressed: () => _pages.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut), icon: const Icon(Symbols.chevron_right_rounded)),
            ],
          ),
          Row(
            children: [
              for (final w in const ['월', '화', '수', '목', '금', '토', '일'])
                Expanded(child: Text(w, textAlign: TextAlign.center, style: t.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 6 * 48,
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (i) => setState(() => _month = _monthAt(i)),
              itemBuilder: (context, i) => _MonthGrid(
                month: _monthAt(i),
                selected: _selected,
                onTap: (d) => setState(() => _selected = d),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Legend(),
          const SizedBox(height: AppSpacing.base),
          if (_selected != null) _DayPanel(day: _selected!),
        ],
      ),
    );
  }
}

/// 한 달 그리드 (월요일 시작, 6주 고정).
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.selected, required this.onTap});

  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onTap;

  /// 6주 × 7일. 앞뒤 달 날짜는 null.
  static List<DateTime?> cells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday - 1; // 월=0
    final days = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(42, (i) {
      final d = i - lead + 1;
      return d < 1 || d > days ? null : DateTime(month.year, month.month, d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final schedule = services.schedule.schedule;
    final checkins = services.schedule.checkinDates;
    final t = context.text;
    final c = context.colors;
    final now = DateTime.now();
    final cellsList = cells(month);
    final historyDays = <String>{for (final r in services.history.items) PickupSchedule.dateKey(r.date)};
    return GridView.count(
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      childAspectRatio: 1,
      children: [
        for (final d in cellsList)
          if (d == null)
            const SizedBox.shrink()
          else
            _DayCell(
              day: d,
              isToday: d.year == now.year && d.month == now.month && d.day == now.day,
              isSelected: selected != null && d.year == selected!.year && d.month == selected!.month && d.day == selected!.day,
              pickupTypes: schedule == null ? const [] : [for (final ty in WasteType.values) if (schedule.daysOf(ty).contains(d.weekday)) ty],
              checked: checkins.contains(PickupSchedule.dateKey(d)),
              hasEvent: services.events.onDay(d).isNotEmpty,
              hasSpecial: services.events.specialOn(d).isNotEmpty,
              hasRecord: historyDays.contains(PickupSchedule.dateKey(d)),
              onTap: () => onTap(d),
              textStyle: t.bodySmall!,
              colors: c,
            ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.pickupTypes,
    required this.checked,
    required this.hasEvent,
    required this.hasSpecial,
    required this.hasRecord,
    required this.onTap,
    required this.textStyle,
    required this.colors,
  });

  final DateTime day;
  final bool isToday, isSelected, checked, hasEvent, hasSpecial, hasRecord;
  final List<WasteType> pickupTypes;
  final VoidCallback onTap;
  final TextStyle textStyle;
  final AppTokens colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? c.primarySoft : null,
          border: isToday ? Border.all(color: c.primary, width: 1.5) : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}', style: textStyle.copyWith(color: isToday ? c.primary : c.textPrimary, fontWeight: isToday ? FontWeight.w700 : null)),
            const SizedBox(height: 3),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (checked)
                    Icon(Symbols.check_rounded, size: 9, color: c.primary, weight: 700)
                  else
                    for (final ty in pickupTypes) _dot(wasteColor(c, ty)),
                  if (hasEvent) _dot(c.ink),
                  if (hasSpecial) _dot(c.textDisabled),
                  if (hasRecord && !checked && pickupTypes.isEmpty && !hasEvent) _dot(c.divider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dot(Color color) => Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// 수거 종류 색 (토큰).
Color wasteColor(AppTokens c, WasteType t) => switch (t) {
      WasteType.recycle => c.recycle,
      WasteType.general => c.general,
      WasteType.food => c.food,
    };

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget item(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: t.bodySmall),
        ]);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final ty in WasteType.values) item(wasteColor(c, ty), ty.label),
        item(c.ink, '내 일정'),
        item(c.textDisabled, '전국 일정'),
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Symbols.check_rounded, size: 12, color: c.primary), Text(' 버렸어요', style: t.bodySmall)]),
      ],
    );
  }
}

/// 선택한 날의 항목: 수거일·체크·기록·일정·전국 일정 + [일정 추가](프리미엄).
class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final t = context.text;
    final c = context.colors;
    final schedule = services.schedule.schedule;
    final key = PickupSchedule.dateKey(day);
    final pickups = schedule == null ? const <WasteType>[] : [for (final ty in WasteType.values) if (schedule.daysOf(ty).contains(day.weekday)) ty];
    final checked = services.schedule.checkinDates.contains(key);
    final events = services.events.onDay(day);
    final specials = services.events.specialOn(day);
    final records = services.history.items.where((r) => PickupSchedule.dateKey(r.date) == key).toList();
    final premium = services.premium.isPremium;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${day.month}월 ${day.day}일 (${weekdays[day.weekday - 1]})', style: t.titleSmall)),
              TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 36)),
                onPressed: () => _addEvent(context, day),
                icon: Icon(premium ? Symbols.add_rounded : Symbols.lock_rounded, size: 18),
                label: const Text('일정 추가'),
              ),
            ],
          ),
          if (pickups.isEmpty && events.isEmpty && specials.isEmpty && records.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('이 날은 수거일도 일정도 없어요.', style: t.bodySmall),
          ],
          for (final ty in pickups)
            _row(context, Symbols.delete_rounded, wasteColor(c, ty), '${ty.label} 수거일', checked ? '버렸어요 ✓' : null),
          for (final e in events)
            _row(context, Symbols.event_rounded, c.ink, e.title, '${e.kind.label}${e.remind ? ' · 전날 20:00 알림' : ''}${e.createdByName.isNotEmpty ? ' · ${e.createdByName}' : ''}',
                onDelete: () => services.events.remove(e.id)),
          for (final s in specials)
            _row(context, Symbols.public_rounded, c.textDisabled, s.title, s.note, onOpen: () => ExternalLinks.open(s.sourceUrl)),
          if (records.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('분류 ${records.length}건: ${records.take(3).map((HistoryRecord r) => r.itemName).join(', ')}${records.length > 3 ? ' 외' : ''}', style: t.bodySmall),
          ],
          if (!premium) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('일정 추가와 알림은 프리미엄에서 열려요. 수거일 표시는 무료예요.', style: t.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, Color color, String title, String? sub, {VoidCallback? onDelete, VoidCallback? onOpen}) {
    final t = context.text;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodyMedium),
                if (sub != null && sub.isNotEmpty) Text(sub, style: t.bodySmall),
              ],
            ),
          ),
          if (onOpen != null) IconButton(onPressed: onOpen, icon: Icon(Symbols.open_in_new_rounded, size: 18, color: c.textSecondary), tooltip: '출처'),
          if (onDelete != null) IconButton(onPressed: onDelete, icon: Icon(Symbols.delete_rounded, size: 18, color: c.textSecondary), tooltip: '삭제'),
        ],
      ),
    );
  }

  static Future<void> _addEvent(BuildContext context, DateTime day) async {
    final services = AppServices.of(context);
    if (!services.premium.isPremium) {
      await ensurePremium(context, reason: '일정 추가는 프리미엄에서 열려요', source: PaywallSource.featureTap);
      return;
    }
    if (!context.mounted) return;
    await showAddEventSheet(context, initialDate: day);
  }
}

/// 일정 추가 시트: 제목·종류·날짜·알림.
Future<void> showAddEventSheet(BuildContext context, {required DateTime initialDate}) {
  final title = TextEditingController();
  var kind = EventKind.bulky;
  var date = initialDate;
  var remind = true;
  return showAppSheet<void>(
    context,
    title: '일정 추가',
    initialSize: 0.62,
    builder: (ctx, controller) => StatefulBuilder(
      builder: (ctx, setState) {
        final t = ctx.text;
        final c = ctx.colors;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            TextField(controller: title, autofocus: true, maxLength: 30, decoration: const InputDecoration(hintText: '예: 소파 대형폐기물 수거')),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final k in EventKind.values)
                  ChoiceChip(label: Text(k.label), selected: kind == k, onSelected: (_) => setState(() => kind = k)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Symbols.calendar_today_rounded, color: c.textPrimary),
              title: Text('${date.year}년 ${date.month}월 ${date.day}일', style: t.bodyMedium),
              trailing: const Text('바꾸기'),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (picked != null) setState(() => date = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: remind,
              onChanged: (v) => setState(() => remind = v),
              title: Text('전날 ${CalendarEvent.remindHour}:00 알림', style: t.bodyMedium),
              subtitle: Text(AppServices.of(ctx).household.active ? '집 멤버 모두에게 각자 폰으로 알려요.' : '이 폰으로 알려요.', style: t.bodySmall),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await AppServices.of(ctx).events.add(title: title.text, kind: kind, date: date, remind: remind);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    ),
  );
}
