import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/theme/app_sheet.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/account_section.dart';
import '../features/household/household_sheet.dart';
import '../features/legal/data_deletion.dart';
import '../features/legal/legal_links.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/legal/legal_webview_screen.dart';
import '../features/paywall/premium_sheet.dart';
import '../features/premium/premium_gate.dart';
import '../features/premium/premium_store.dart';
import '../features/premium/purchases_service.dart';
import '../features/premium/subscription_status.dart';
import '../features/places/external_links.dart';
import '../features/places/region_picker_sheet.dart';
import '../features/schedule/notification_service.dart';
import '../features/schedule/pickup_schedule.dart';
import '../features/schedule/schedule_settings_sheet.dart';
import '../widgets/app_card.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/analytics.dart';
import '../features/notifications/notification_settings_screen.dart';

/// 설정 바텀시트. 프리미엄·집·지역·수거일·계정·약관·앱 정보.
Future<void> showSettingsSheet(BuildContext context) {
  Analytics.screen('settings');
  final services = AppServices.of(context);
  final session = services.firebase;
  final region = services.region;
  return showAppSheet(
    context,
    title: '설정',
    initialSize: 0.55,
    builder: (ctx, controller) => ListenableBuilder(
      listenable: Listenable.merge([session, region, services.household]),
      builder: (ctx, _) {
        final c = ctx.colors;
        final t = ctx.text;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Text('프리미엄', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            ListenableBuilder(
              listenable: services.premium,
              builder: (ctx2, _) {
                final p = services.premium;
                final st = p.status;
                // 제목·부제: 체험/갱신/해지 예정은 RevenueCat 상태로, 가격은 스토어 값으로만.
                final String title;
                final String subtitle;
                if (p.source == PremiumSource.own) {
                  final price = st.isYearly ? p.yearlyPrice : p.monthlyPrice;
                  title = st.headline(priceString: price);
                  subtitle = st.phase == SubscriptionPhase.cancelled ? '탭하면 Google Play 구독 관리로 가요' : '프리미엄 관리 · 갱신일·구독 관리';
                } else if (p.source == PremiumSource.family) {
                  title = 'ReSAI 프리미엄 사용 중';
                  subtitle = '집 방장의 구독 · 프리미엄 관리';
                } else if (p.isPremium) {
                  title = 'ReSAI 프리미엄 사용 중';
                  subtitle = '프리미엄 관리';
                } else {
                  title = 'ReSAI 프리미엄';
                  final m = p.monthlyPrice;
                  final y = p.yearlyPrice;
                  subtitle = m == null || y == null
                      ? (p.pricesFailed ? '7일 무료 체험 · 가격을 불러오지 못했어요' : '7일 무료 체험 · 가격 불러오는 중…')
                      : '7일 무료 체험 · 월 $m · 연 $y';
                  if (!p.isPremium && p.offering == null && !p.pricesLoading && p.available) {
                    // 설정을 열 때마다 한 번 더 시도 (오프라인이었다가 돌아온 경우).
                    WidgetsBinding.instance.addPostFrameCallback((_) => p.loadOffering());
                  }
                }
                return AppCard(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (p.source == PremiumSource.own && st.phase == SubscriptionPhase.cancelled) {
                      Analytics.log('manage_subscription_tap', {'from': 'settings_card'});
                      ExternalLinks.open(PremiumConfig.manageUrl(p.productId));
                    } else if (p.isPremium) {
                      showPremiumSheet(context);
                    } else {
                      maybeShowPaywall(context, source: PaywallSource.settings);
                    }
                  },
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Icon(Symbols.family_restroom_rounded, color: p.isPremium ? c.primary : c.textPrimary, fill: p.isPremium ? 1 : 0),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: t.titleSmall),
                            Text(subtitle, style: t.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('우리 집', style: t.titleSmall),
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
                  Expanded(child: Text(services.household.active ? '${services.household.household!.name} · 멤버 ${services.household.members.length}명' : '집 만들기 · 코드로 참여', style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('거주 지역', style: t.titleSmall),
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
                  Expanded(child: Text(region.displayName, style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('우리 동네 배출 기준 안내, 대형폐기물 신고, 수거함 안내에 써요. 위치 권한은 쓰지 않아요.', style: t.bodySmall),
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
                  Expanded(child: Text('수거일 설정', style: t.titleSmall)),
                  Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () {
                Navigator.pop(ctx);
                context.pushPage(const NotificationSettingsScreen());
              },
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Icon(Symbols.notifications_rounded, color: c.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('알림', style: t.titleSmall)),
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
            Text('계정', style: t.titleSmall),
            const SizedBox(height: AppSpacing.md),
            const AccountSection(),
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
                    icon: Symbols.replay_rounded,
                    label: '온보딩 다시 보기',
                    // 스플래시 풀 버전 → 1 → 2 → 홈 (동의·첫 분류 연출은 다시 하지 않는다)
                    onTap: () {
                      Navigator.pop(ctx);
                      context.pushPage(OnboardingScreen(
                        replay: true,
                        onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      ));
                    },
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
            _AppInfo(
              child: Text(
                'ReSAI(리사이) 1.0.1\n'
                '사진 한 장으로 올바른 분리배출 방법을 알려주는 앱이에요.\n'
                '판별 결과는 참고용이며, 최종 기준은 거주 지역 지자체 안내를 따라 주세요.',
                style: t.bodyMedium?.copyWith(color: c.textSecondary),
              ),
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


/// 앱 정보를 7번 탭하면 검토자 코드 입력창. Play 검토자가 결제 없이 프리미엄을 확인하는 용도.
class _AppInfo extends StatefulWidget {
  const _AppInfo({required this.child});

  final Widget child;

  @override
  State<_AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<_AppInfo> {
  int _taps = 0;

  Future<void> _tap() async {
    _taps++;
    if (_taps < 7) return;
    _taps = 0;
    final premium = AppServices.of(context).premium;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('검토자 코드'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reviewer code'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('확인')),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final ok = await premium.tryReviewCode(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '검토 모드: 프리미엄이 ${PremiumConfig.reviewDays}일 동안 열렸어요.' : '코드가 맞지 않아요.'),
    ));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, child: widget.child);
}
