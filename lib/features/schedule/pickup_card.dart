import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../stats/streak_row.dart';
import '../household/household_model.dart';
import 'pickup_schedule.dart';
import 'schedule_settings_sheet.dart';
import 'schedule_store.dart';

/// 홈 상단 수거일 카드.
/// 설정 전 → 설정 버튼 / 오늘 수거일 → 큰 카드 + [버렸어요] / 그 외 → 가까운 수거일 3개.
class PickupCard extends StatelessWidget {
  const PickupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).schedule;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isConfigured) return const _NotConfigured();
        final snap = store.snapshot(DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snap.today.isNotEmpty) ...[
              _TodayCard(types: snap.today, store: store),
              if (snap.upcoming.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            ],
            if (snap.upcoming.isNotEmpty) _UpcomingCard(items: snap.upcoming, compact: snap.today.isNotEmpty),
            StreakBadge(weeks: store.streak(DateTime.now()).weeks),
          ],
        );
      },
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return AppCard(
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.calendar_today_rounded, size: 24, color: c.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text('우리 동네 수거일', style: t.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('요일을 정해두면 전날 저녁에 알려드리고, 홈 위젯에도 D-day 가 떠요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.base),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            onPressed: () => showScheduleSettingsSheet(context),
            child: const Text('수거일 설정하기'),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.types, required this.store});

  final List<WasteType> types;
  final ScheduleStore store;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final allDone = types.every(store.isChecked);
    final names = types.map((x) => x.label).join('·');
    return AppCard(
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(allDone ? Symbols.check_circle_rounded : Symbols.delete_rounded, size: 24, color: c.primary, fill: allDone ? 1 : 0),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(allDone ? '오늘 $names 버렸어요' : '오늘 $names 버리는 날!', style: t.headlineSmall?.copyWith(fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(allDone ? '잘하셨어요. 내일도 알려드릴게요.' : '모아둔 거 한 번에 내놓고, 버렸으면 눌러주세요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.base),
          for (var i = 0; i < types.length; i++) ...[
            _CheckRow(type: types[i], checked: store.isChecked(types[i]), member: store.memberCheckins[types[i]], onCheck: () {
              HapticFeedback.mediumImpact();
              store.checkIn(types[i]);
            }),
            if (i != types.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.type, required this.checked, required this.onCheck, this.member});

  final WasteType type;
  final bool checked;

  /// 집 멤버가 체크했으면 누가·언제.
  final MemberCheckin? member;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    if (checked) {
      return Row(
        children: [
          Icon(Symbols.check_circle_rounded, size: 20, color: c.primary, fill: 1),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              member != null && member!.nickname.isNotEmpty
                  ? '${member!.nickname}가 오늘 ${type.label} 버렸어요 · ${member!.timeLabel}'
                  : '${type.label} 버렸어요',
              style: t.titleSmall?.copyWith(color: c.primary),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: Text(type.label, style: t.titleSmall)),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base)),
            onPressed: onCheck,
            icon: const Icon(Symbols.check_rounded, size: 20),
            label: const Text('버렸어요'),
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.items, required this.compact});

  final List<UpcomingPickup> items;

  /// 오늘 카드가 위에 있을 때는 작게.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return AppCard(
      onTap: () => showScheduleSettingsSheet(context),
      padding: EdgeInsets.all(compact ? AppSpacing.base : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(compact ? '다음 수거일' : '우리 동네 수거일', style: compact ? t.bodySmall : t.titleSmall)),
              Icon(Symbols.chevron_right_rounded, size: 20, color: c.textDisabled),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(child: Text(items[i].type.label, style: t.bodyMedium)),
                Text('(${PickupSchedule.weekdayLabel(items[i].date.weekday)})', style: t.bodySmall),
                const SizedBox(width: AppSpacing.sm),
                Text(items[i].dDayLabel, style: t.titleSmall?.copyWith(fontSize: compact ? 15 : 18)),
              ],
            ),
            if (i != items.length - 1) SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
