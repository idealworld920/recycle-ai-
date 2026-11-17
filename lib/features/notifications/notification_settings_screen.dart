import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../premium/subscription_status.dart';
import '../schedule/notification_service.dart';
import 'notification_prefs.dart';

/// 설정 → 알림. 표준 존댓말, 리뿅이 없음. 종류별 토글 + 시각 + 방해 금지.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  static const _channel = MethodChannel('resai/system');

  static Future<void> openSystemSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool? _systemEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Analytics.screen('notification_settings');
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final on = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _systemEnabled = on);
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial, String help) => showTimePicker(context: context, initialTime: initial, helpText: help);

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final store = services.notificationPrefs;
    final t = context.text;
    final c = context.colors;
    if (store == null) {
      return Scaffold(appBar: AppBar(title: const Text('알림')), body: const Center(child: Text('알림 설정을 불러오지 못했어요.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, services.schedule, services.household, services.premium]),
        builder: (context, _) {
          final p = store.value;
          final schedule = services.schedule.schedule;
          final inHousehold = services.household.active;
          final inTrial = services.premium.status.phase == SubscriptionPhase.trial;
          bool quietWarning(TimeOfDay time) => p.quiet.contains(DateTime(2000, 1, 1, time.hour, time.minute));
          final eveTime = TimeOfDay(hour: schedule?.notifyHour ?? 20, minute: schedule?.notifyMinute ?? 0);
          final morningTime = TimeOfDay(hour: p.morningHour, minute: p.morningMinute);

          Widget toggle(NotificationType type, {String? subtitle, Widget? trailing}) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(type.label, style: t.titleSmall),
                subtitle: subtitle == null ? null : Text(subtitle, style: t.bodySmall),
                value: p.isOn(type),
                onChanged: (v) => store.setEnabled(type, v),
              );

          Widget timeRow(String label, TimeOfDay time, VoidCallback onTap, {bool enabled = true}) => InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Symbols.schedule_rounded, size: 20, color: enabled ? c.textSecondary : c.textDisabled),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: enabled ? c.textPrimary : c.textDisabled))),
                      Text(time.format(context), style: t.bodyMedium?.copyWith(color: enabled ? c.primary : c.textDisabled)),
                      if (quietWarning(time)) ...[const SizedBox(width: AppSpacing.xs), Icon(Symbols.bedtime_rounded, size: 16, color: c.warningText)],
                    ],
                  ),
                ),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: [
              if (_systemEnabled == false)
                AppCard(
                  soft: true,
                  onTap: NotificationSettingsScreen.openSystemSettings,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Icon(Symbols.notifications_off_rounded, color: c.warningText),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text('알림이 꺼져 있어요 · 시스템 설정 열기', style: t.titleSmall)),
                      Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                    ],
                  ),
                ),
              if (_systemEnabled == false) const SizedBox(height: AppSpacing.lg),
              Text('수거일', style: t.titleSmall),
              toggle(NotificationType.pickupEve, subtitle: schedule == null || schedule.isEmpty ? '수거일을 설정하면 울려요' : null),
              timeRow('전날 저녁 알림 시각', eveTime, () async {
                final picked = await _pickTime(eveTime, '수거일 전날 알림 시각');
                if (picked == null || schedule == null) return;
                await services.schedule.save(schedule.copyWith(notifyHour: picked.hour, notifyMinute: picked.minute));
              }, enabled: p.isOn(NotificationType.pickupEve) && schedule != null && !schedule.isEmpty),
              toggle(NotificationType.pickupMorning, subtitle: '알림에서 바로 [버렸뿅!] 을 누를 수 있어요'),
              timeRow('당일 아침 알림 시각', morningTime, () async {
                final picked = await _pickTime(morningTime, '수거일 당일 알림 시각');
                if (picked != null) await store.setMorningTime(picked.hour, picked.minute);
              }, enabled: p.isOn(NotificationType.pickupMorning)),
              toggle(NotificationType.specialDay, subtitle: '공휴일 등 수거를 쉬는 날 전날 저녁에 알려드려요 (거주 지역 설정 필요)'),
              const Divider(height: AppSpacing.xl),
              Text('리포트·소식', style: t.titleSmall),
              toggle(NotificationType.weeklyReport, subtitle: '일요일 저녁 8시. 그 주에 분류한 게 없으면 보내지 않아요'),
              toggle(NotificationType.comeback, subtitle: '3일 동안 안 열었을 때 한 번만'),
              if (inHousehold) ...[
                const Divider(height: AppSpacing.xl),
                Text('가족 공유', style: t.titleSmall),
                toggle(NotificationType.familyCheckin, subtitle: '가족이 버렸다고 체크하면 알려드려요'),
                toggle(NotificationType.familyReminder, subtitle: '수거일 저녁 9시까지 아무도 체크하지 않았을 때'),
              ],
              if (inTrial) ...[
                const Divider(height: AppSpacing.xl),
                Text('구독', style: t.titleSmall),
                toggle(NotificationType.trialEnd, subtitle: p.isOn(NotificationType.trialEnd) ? '체험 종료 2일 전·1일 전에 알려드려요' : '체험 종료 전 알림을 받지 못해요'),
              ],
              const Divider(height: AppSpacing.xl),
              Text('방해 금지 시간', style: t.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('이 시간에는 어떤 알림도 보내지 않고, 끝나는 시각으로 미뤄요.', style: t.bodySmall),
              Row(
                children: [
                  Expanded(
                    child: timeRow('시작', TimeOfDay(hour: p.quiet.startMinutes ~/ 60, minute: p.quiet.startMinutes % 60), () async {
                      final picked = await _pickTime(TimeOfDay(hour: p.quiet.startMinutes ~/ 60, minute: p.quiet.startMinutes % 60), '방해 금지 시작');
                      if (picked != null) await store.setQuietHours(QuietHours(startMinutes: picked.hour * 60 + picked.minute, endMinutes: p.quiet.endMinutes));
                    }),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: timeRow('종료', TimeOfDay(hour: p.quiet.endMinutes ~/ 60, minute: p.quiet.endMinutes % 60), () async {
                      final picked = await _pickTime(TimeOfDay(hour: p.quiet.endMinutes ~/ 60, minute: p.quiet.endMinutes % 60), '방해 금지 종료');
                      if (picked != null) await store.setQuietHours(QuietHours(startMinutes: p.quiet.startMinutes, endMinutes: picked.hour * 60 + picked.minute));
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('알림 권한은 수거일을 처음 저장할 때 한 번만 물어봐요. 정확한 알람 권한은 쓰지 않아서 몇 분 늦게 올 수 있어요.', style: t.bodySmall),
            ],
          );
        },
      ),
    );
  }
}
