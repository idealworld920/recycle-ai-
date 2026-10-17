import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/account_section.dart';
import '../features/household/household_sheet.dart';
import '../features/legal/data_deletion.dart';
import '../features/legal/legal_links.dart';
import '../features/legal/legal_webview_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/places/region_picker_sheet.dart';
import '../features/schedule/notification_service.dart';
import '../features/schedule/pickup_schedule.dart';
import '../features/schedule/schedule_settings_sheet.dart';
import '../widgets/app_card.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 설정 바텀시트. AI 연결 상태와 앱 정보.
Future<void> showSettingsSheet(BuildContext context) {
  final session = AppServices.of(context).firebase;
  final region = AppServices.of(context).region;
  return showAppSheet(
    context,
    title: '설정',
    initialSize: 0.55,
    builder: (ctx, controller) => ListenableBuilder(
      listenable: Listenable.merge([session, region]),
      builder: (ctx, _) {
        final c = ctx.colors;
        final t = ctx.text;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            const AccountSection(),
            const SizedBox(height: AppSpacing.xl),
            Text('프리미엄', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            ListenableBuilder(
              listenable: AppServices.of(context).premium,
              builder: (ctx2, _) {
                final p = AppServices.of(context).premium;
                return AppCard(
                  onTap: p.isPremium ? null : () {
                    Navigator.pop(ctx);
                    context.pushPage(const PaywallScreen());
                  },
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Icon(Symbols.workspace_premium_rounded, color: p.isPremium ? c.primary : c.textPrimary, fill: p.isPremium ? 1 : 0),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.isPremium ? '프리미엄 사용 중' : 'ReSAI 프리미엄', style: t.titleSmall),
                            Text(p.isPremium ? '분류·질문 무제한, 가족 공유' : '7일 무료 체험 · 월 2,900원', style: t.bodySmall),
                          ],
                        ),
                      ),
                      if (!p.isPremium) Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('가족 공유', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () {
                Navigator.pop(ctx);
                showHouseholdSheet(context);
              },
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(Symbols.family_restroom_rounded, color: c.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('집 만들기 · 참여하기', style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('내 지역', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () {
                Navigator.pop(ctx);
                showRegionPickerSheet(context);
              },
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(Symbols.location_on_rounded, color: c.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(regionLabel(region.selected), style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('대형폐기물 신고, 수거함 안내에 써요. 위치 권한은 쓰지 않아요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            Text('수거일', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () {
                Navigator.pop(ctx);
                showScheduleSettingsSheet(context);
              },
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(Symbols.calendar_today_rounded, color: c.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('수거일·알림 시각 설정', style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => NotificationService.instance.showTest(WasteType.recycle),
              child: const Text('테스트 알림 보내기 (5초 뒤)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('AI 연결', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(
                    session.ready ? Symbols.check_circle_rounded : Symbols.cloud_off_rounded,
                    color: session.ready ? c.primary : c.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.ready ? '연결됨' : (session.busy ? '연결하는 중' : '연결 안 됨'), style: t.titleSmall),
                        if (session.ready && session.uid != null)
                          Text('익명 ID ${session.uid!.substring(0, 6)}…', style: t.bodySmall)
                        else if (session.error != null)
                          Text(session.error!, style: t.bodySmall),
                      ],
                    ),
                  ),
                  if (!session.ready && !session.busy) TextButton(onPressed: session.init, child: const Text('다시 연결')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('API 키는 앱에 저장되지 않아요. Firebase 가 대신 AI 를 호출해요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.xxl),
            Text('약관 및 개인정보', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  _LinkRow(
                    icon: Symbols.description_rounded,
                    label: '이용약관',
                    onTap: () => LegalWebViewScreen.open(context, title: '이용약관', url: LegalLinks.terms),
                  ),
                  const Divider(),
                  _LinkRow(
                    icon: Symbols.privacy_tip_rounded,
                    label: '개인정보처리방침',
                    onTap: () => LegalWebViewScreen.open(context, title: '개인정보처리방침', url: LegalLinks.privacy),
                  ),
                  const Divider(),
                  _LinkRow(
                    icon: Symbols.delete_forever_rounded,
                    label: '내 데이터 삭제',
                    color: c.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      showDeleteDataSheet(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('앱 정보', style: t.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ReSAI(리사이) 1.0.0\n'
              '사진 한 장으로 올바른 분리배출 방법을 알려주는 앱이에요.\n'
              '판별 결과는 참고용이며, 최종 기준은 거주 지역 지자체 안내를 따라 주세요.',
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        );
      },
    ),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? c.textPrimary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: color ?? c.textPrimary))),
            Icon(Symbols.chevron_right_rounded, size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
