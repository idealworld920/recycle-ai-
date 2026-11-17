import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/link_flows.dart';
import '../legal/legal_links.dart';
import '../places/external_links.dart';
import '../premium/premium_store.dart';
import '../premium/purchase_errors.dart';
import '../premium/purchases_service.dart';
import '../../core/analytics.dart';
import '../premium/premium_gate.dart';
import '../review/review_prompter.dart';
import '../premium/price_format.dart';
import '../premium/trial_reminders.dart';
import 'paywall_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 프리미엄 페이월. 결제가 끝나면 true 를 돌려준다. 취소는 조용히 닫는다.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason, this.source = PaywallSource.settings});

  /// 어디서 열렸는지 (paywall_view.source).
  final PaywallSource source;

  /// 어디서 왔는지 한 줄 (예: "오늘 무료 분류 10회를 다 썼어요").
  final String? reason;

  /// (아이콘, 제목, 부제)
  static const benefits = [
    (Symbols.family_restroom_rounded, '가족·룸메 6명까지 함께', '한 명만 구독하면 모두 프리미엄'),
    (Symbols.photo_camera_rounded, '사진 분류 무제한', null),
    (Symbols.chat_bubble_rounded, 'AI 질문 무제한', null),
    (Symbols.calendar_month_rounded, '캘린더 일정 + 여러 장 분류', null),
  ];

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;
  bool _askedLink = false;

  String get _plan => _yearly ? 'yearly' : 'monthly';
  bool _purchased = false;

  /// 결제 없이 닫힘: 7일 쿨다운 기록 + paywall_dismiss.
  Future<void> _onDismissed() async {
    if (_purchased) return;
    Analytics.log('paywall_dismiss', {'source': widget.source.analyticsName});
    final services = AppServices.of(context);
    final trigger = PaywallTrigger(await SharedPreferences.getInstance());
    await trigger.markDismissed(remote: services.auth.service.mergeUserDoc);
  }

  @override
  void initState() {
    super.initState();
    Analytics.screen('paywall');
    Analytics.log('paywall_view', {'source': widget.source.analyticsName});
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = AppServices.of(context);
      await services.premium.loadOffering();
      // 복원을 위해 연결을 권장 (필수 아님). 한 번만.
      if (!_askedLink && services.premium.available && services.auth.isAnonymous && mounted) {
        _askedLink = true;
        await recommendLinkBeforePurchase(context);
      }
    });
  }

  Future<void> _buy() async {
    final store = AppServices.of(context).premium;
    if (!store.available) {
      _toast('결제는 스토어 심사가 끝나면 열려요. 조금만 기다려 주세요.');
      return;
    }
    final pkg = _yearly ? store.yearly : store.monthly;
    if (pkg == null) {
      _toast('상품 정보를 아직 불러오지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.');
      return;
    }
    // 체험 자격이 있으면 체험 오퍼로, 아니면 기본 요금제로. 옵션 정보가 없으면 Play 기본 동작.
    final option = PremiumStore.trialOption(pkg) ?? PremiumStore.basePlanOption(pkg);
    final trial = PremiumStore.trialEligible(pkg);
    Analytics.log('purchase_start', {'plan': _plan});
    final r = option != null ? await store.purchaseOption(option) : await store.purchase(pkg);
    if (!mounted) return;
    switch (r) {
      case PurchaseSuccess():
        _purchased = true;
        Analytics.log('purchase_success', {'plan': _plan, 'is_trial': trial});
        Analytics.log('badge_earned', {'level': 'crown'});
        ReviewPrompter.purchasedThisSession = true;
        if (trial) unawaited(TrialReminders.schedule(AppServices.of(context)));
        _toast(trial ? 'ReSAI 프리미엄이 시작됐어요. ${PremiumConfig.trialDays}일 동안 무료예요.' : 'ReSAI 프리미엄이 시작됐어요.');
        Navigator.pop(context, true);
      case PurchaseCancelled():
        Analytics.log('purchase_fail', {'plan': _plan, 'reason': 'cancelled'});
      case PurchasePending():
        _toast('결제가 승인 대기 중이에요. 완료되면 자동으로 열려요.');
      case PurchaseFailed(:final message):
        Analytics.log('purchase_fail', {'plan': _plan, 'reason': 'error'});
        _toast(message);
    }
  }

  Future<void> _restore() async {
    Analytics.log('restore_tap', {'from': 'paywall'});
    final r = await AppServices.of(context).premium.restore();
    if (!mounted) return;
    switch (r) {
      case PurchaseSuccess():
        _purchased = true;
        Analytics.log('restore_success');
        _toast('구독을 복원했어요.');
        Navigator.pop(context, true);
      case PurchaseFailed(:final message):
        _toast(message);
      default:
        break;
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).premium;
    final t = context.text;
    final c = context.colors;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result != true) _onDismissed();
      },
      child: Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final pkg = _yearly ? store.yearly : store.monthly;
          final yearlyNote = store.yearly == null ? null : PriceFormat.yearlyEquivalent(store.yearly!.storeProduct.price, store.yearly!.storeProduct.currencyCode);
          final monthlyNote = store.monthly == null ? null : PriceFormat.monthlyEquivalent(store.monthly!.storeProduct.price, store.monthly!.storeProduct.currencyCode);
          // 체험 자격: Play 오퍼(freePhase) 또는 introductoryPrice. 상품을 못 받았으면 체험 버튼도 안 보여준다.
          final trial = PremiumStore.trialEligible(pkg);
          final loading = store.pricesLoading;
          final yearlyPrice = store.yearlyPrice;
          final monthlyPrice = store.monthlyPrice;
          final priceString = _yearly ? yearlyPrice : monthlyPrice;
          final price = priceString == null ? null : (_yearly ? '연 $priceString' : '월 $priceString');
          final discount = store.yearlyDiscountPercent;
          final priceHint = loading ? '가격 불러오는 중…' : '가격을 불러오지 못했어요';
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: [
              const Center(child: MascotImage(Mascot.happy, size: 112)),
              const SizedBox(height: AppSpacing.base),
              Text('ReSAI 프리미엄', style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('분리수거, 더 편하게', style: t.bodyMedium?.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              if (widget.reason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(widget.reason!, style: t.bodySmall, textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.xl),
              for (final (icon, text, sub) in PaywallScreen.benefits) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: c.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text, style: t.bodyMedium?.copyWith(fontWeight: sub == null ? null : FontWeight.w600)),
                          if (sub != null) Text(sub, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _PlanTile(
                      selected: _yearly,
                      title: '연간',
                      price: yearlyPrice == null ? priceHint : '$yearlyPrice / 년',
                      note: yearlyNote,
                      badge: discount == null ? null : '$discount% 할인',
                      onTap: () {
                        setState(() => _yearly = true);
                        Analytics.log('paywall_select_plan', {'plan': 'yearly'});
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PlanTile(
                      selected: !_yearly,
                      title: '월간',
                      price: monthlyPrice == null ? priceHint : '$monthlyPrice / 월',
                      note: monthlyNote,
                      onTap: () {
                        setState(() => _yearly = false);
                        Analytics.log('paywall_select_plan', {'plan': 'monthly'});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: c.ink, foregroundColor: c.onInk),
                onPressed: store.busy || pkg == null ? null : _buy,
                child: Text(store.busy
                    ? '처리하는 중…'
                    : pkg == null
                        ? priceHint
                        : trial
                            ? '${PremiumConfig.trialDays}일 무료로 시작'
                            : '구독 시작 · $price'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (pkg == null && store.pricesFailed)
                TextButton(onPressed: store.loadOffering, child: const Text('다시 불러오기'))
              else if (pkg != null) ...[
                Text(
                  trial
                      ? '${PremiumConfig.trialDays}일 무료 체험 후 $price 자동 갱신돼요.'
                      : '$price 자동 갱신돼요. Google Play 구독 관리에서 언제든 해지할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
                if (trial) Text('체험 종료 2일 전에 알려드려요. 언제든 해지할 수 있어요.', textAlign: TextAlign.center, style: t.bodySmall),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text('집 방장이 구독하면 멤버 모두(최대 6명)에게 적용돼요.', textAlign: TextAlign.center, style: t.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                    onPressed: store.busy ? null : _restore,
                    child: const Text('구매 복원'),
                  ),
                  Text('·', style: t.bodySmall),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                    onPressed: () => ExternalLinks.open(LegalLinks.terms),
                    child: const Text('이용약관'),
                  ),
                  Text('·', style: t.bodySmall),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                    onPressed: () => ExternalLinks.open(LegalLinks.privacy),
                    child: const Text('개인정보처리방침'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.selected, required this.title, required this.price, required this.onTap, this.badge, this.note});

  final bool selected;
  final String title;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  /// 환산 문구 (연간: "월 1,658원 · 하루 55원", 월간: "하루 97원"). 스토어 가격으로 계산.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Material(
      color: selected ? c.primarySoft : c.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: selected ? c.primary : c.divider, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: t.titleSmall),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(AppRadius.chip)),
                      child: Text(badge!, style: t.labelSmall?.copyWith(color: c.onInk, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(price, style: t.bodySmall?.copyWith(color: c.textPrimary)),
              if (note != null) Text(note!, style: t.labelSmall?.copyWith(color: c.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
