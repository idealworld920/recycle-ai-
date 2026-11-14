import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

/// 프리미엄 페이월. 결제가 끝나면 true 를 돌려준다. 취소는 조용히 닫는다.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// 어디서 왔는지 한 줄 (예: "오늘 무료 분류 10회를 다 썼어요").
  final String? reason;

  static const benefits = [
    (Symbols.photo_camera_rounded, '사진 분류 무제한'),
    (Symbols.chat_bubble_rounded, 'AI 질문 무제한'),
    (Symbols.family_restroom_rounded, '가족·룸메와 수거일 공유'),
    (Symbols.calendar_month_rounded, '캘린더 일정 + 여러 장 분류'),
  ];

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;
  bool _askedLink = false;

  @override
  void initState() {
    super.initState();
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

  String _price(Package? p, String fallback) => p?.storeProduct.priceString ?? fallback;

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
    final r = option != null ? await store.purchaseOption(option) : await store.purchase(pkg);
    if (!mounted) return;
    switch (r) {
      case PurchaseSuccess():
        _toast(PremiumStore.trialOption(pkg) != null ? 'ReSAI 프리미엄이 시작됐어요. 7일 동안 무료예요.' : 'ReSAI 프리미엄이 시작됐어요.');
        Navigator.pop(context, true);
      case PurchaseCancelled():
        break; // 조용히
      case PurchasePending():
        _toast('결제가 승인 대기 중이에요. 완료되면 자동으로 열려요.');
      case PurchaseFailed(:final message):
        _toast(message);
    }
  }

  Future<void> _restore() async {
    final r = await AppServices.of(context).premium.restore();
    if (!mounted) return;
    switch (r) {
      case PurchaseSuccess():
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
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final pkg = _yearly ? store.yearly : store.monthly;
          final trial = pkg == null || PremiumStore.trialOption(pkg) != null;
          final yearlyPrice = _price(store.yearly, PremiumConfig.yearlyPriceFallback);
          final monthlyPrice = _price(store.monthly, PremiumConfig.monthlyPriceFallback);
          final price = _yearly ? '연 $yearlyPrice' : '월 $monthlyPrice';
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
              for (final (icon, text) in PaywallScreen.benefits) ...[
                Row(
                  children: [
                    Icon(icon, size: 22, color: c.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(text, style: t.bodyMedium)),
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
                      price: '$yearlyPrice / 년',
                      badge: '43% 할인',
                      onTap: () => setState(() => _yearly = true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PlanTile(
                      selected: !_yearly,
                      title: '월간',
                      price: '$monthlyPrice / 월',
                      onTap: () => setState(() => _yearly = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: c.ink, foregroundColor: c.onInk),
                onPressed: store.busy ? null : _buy,
                child: Text(store.busy ? '처리하는 중…' : (trial ? '${PremiumConfig.trialDays}일 무료로 시작' : '구독 시작 · $price')),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                trial
                    ? '${PremiumConfig.trialDays}일 무료 체험 후 $price 자동 갱신돼요. 체험 중 해지하면 요금이 청구되지 않아요.'
                    : '$price 자동 갱신돼요. Google Play 구독 관리에서 언제든 해지할 수 있어요.',
                textAlign: TextAlign.center,
                style: t.bodySmall,
              ),
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
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.selected, required this.title, required this.price, required this.onTap, this.badge});

  final bool selected;
  final String title;
  final String price;
  final String? badge;
  final VoidCallback onTap;

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
            ],
          ),
        ),
      ),
    );
  }
}
