import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../legal/permission_primer.dart';
import 'pickup_schedule.dart';

/// 수거일 설정 바텀시트. 종류별 요일 토글 + 알림 시각.
Future<void> showScheduleSettingsSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '수거일 설정',
    initialSize: 0.9,
    builder: (ctx, controller) => _ScheduleForm(controller: controller),
  );
}

class _ScheduleForm extends StatefulWidget {
  const _ScheduleForm({required this.controller});

  final ScrollController controller;

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  late PickupSchedule _draft;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _draft = AppServices.of(context).schedule.schedule ?? const PickupSchedule();
      _loaded = true;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _draft.notifyHour, minute: _draft.notifyMinute),
      helpText: '수거일 전날 알림 시각',
    );
    if (picked != null) setState(() => _draft = _draft.copyWith(notifyHour: picked.hour, notifyMinute: picked.minute));
  }

  Future<void> _save() async {
    final store = AppServices.of(context).schedule;
    if (!_draft.isEmpty && !await PermissionPrimer.show(context, PermissionPrimer.notification)) return;
    if (!mounted) return;
    await store.save(_draft);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_draft.isEmpty ? '수거일 설정을 지웠어요.' : '저장했어요. 전날 ${_draft.notifyTimeLabel}에 알려드릴게요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).schedule;
    final t = context.text;
    final c = context.colors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              Text('종류별로 수거 요일을 골라주세요. 여러 날 선택할 수 있어요.', style: t.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              for (final type in WasteType.values) ...[
                Text(type.label, style: t.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      AppChip(
                        label: PickupSchedule.weekdayShort(d),
                        selected: _draft.daysOf(type).contains(d),
                        onTap: () => setState(() => _draft = _draft.toggleDay(type, d)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text('알림 시각', style: t.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                onTap: _pickTime,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.base),
                child: Row(
                  children: [
                    Icon(Symbols.notifications_rounded, size: 24, color: c.textPrimary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text('수거일 전날 ${_draft.notifyTimeLabel}', style: t.titleSmall)),
                    Text('변경', style: t.labelLarge?.copyWith(color: c.primary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('저장하면 알림 권한을 요청해요. 알림은 수거일 전날 이 시각에 와요.', style: t.bodySmall),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
          child: ListenableBuilder(
            listenable: store,
            builder: (_, _) => FilledButton(
              onPressed: store.saving ? null : _save,
              child: Text(store.saving ? '저장하는 중…' : '저장'),
            ),
          ),
        ),
      ],
    );
  }
}
