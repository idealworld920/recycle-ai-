import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../auth/link_flows.dart';
import '../places/external_links.dart';
import 'purchase_errors.dart';

/// 프리미엄 페이월. 성공하면 true 를 돌려준다.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// 어디서 왔는지 한 줄 (예: "오늘 무료 분류 5회를 다 썼어요").
  final String? reason;

  static const termsUrl = 'https://idealworld920.github.io/recycle-ai-/terms.html';
  static const privacyUrl = 'https://idealworld920.github.io/recycle-ai-/privacy.html';

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
      if (!_askedLink && services.auth.isAnonymous && mounted) {
        _askedLink = true;
        await recommendLinkBeforePurchase(context);
      }
    });
  }

  Future<void> _buy() async {
    final store = AppServices.of(context).premium;
    final pkg = _yearly ? store.yearly : store.monthly;
    if (pkg == null) {
      _toast('상품 정보를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    final r = await store.purchase(pkg);
    if (!mounted) return;
    _handle(r, successMessage: '프리미엄이 시작됐어요. 7일 동안 무료예요.');
  }

  Future<void> _restore() async {
    final r = await AppServices.of(context).premium.restore();
    if (!mounted) return;
    _handle(r, successMessage: '구독을 복원했어요.');
  }

  void _handle(PurchaseOutcome r, {required String successMessage}) {
    switch (r) {
      case PurchaseSuccess():
        _toast(successMessage);
        Navigator.pop(context, true);
      case PurchaseCancelled():
        break; // 취소는 조용히
      case PurchasePending():
        _toast('결제가 승인 대기 중이에요. 완료되면 자동으로 열려요.');
      case PurchaseFailed(:final message):
        _toast(message);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _price(Package? p, String fallback) => p?.storeProduct.priceString ?? fallback;

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).premium;
    final t = context.text;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(AppSpacing.base)),
              child: Text('R', style: t.headlineSmall?.copyWith(color: c.onInk, fontSize: 28)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('ReSAI 프리미엄', style: t.headlineSmall),
            if (widget.reason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(widget.reason!, style: t.bodySmall),
            ],
            const SizedBox(height: AppSpacing.xl),
            const _Benefit(icon: Symbols.photo_camera_rounded, text: '사진 분류와 AI 질문 무제한'),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(icon: Symbols.family_restroom_rounded, text: '가족·룸메와 수거일과 체크를 함께'),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(icon: Symbols.bar_chart_rounded, text: '월간 상세 리포트와 12주 기록'),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _PlanTile(
                    selected: _yearly,
                    title: '연간',
                    price: '${_price(store.yearly, '19,900원')} / 년',
                    badge: '43% 할인',
                    onTap: () => setState(() => _yearly = true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PlanTile(
                    selected: !_yearly,
                    title: '월간',
                    price: '${_price(store.monthly, '2,900원')} / 월',
                    onTap: () => setState(() => _yearly = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: store.busy ? null : _buy,
              child: Text(store.busy ? '처리하는 중…' : '7일 무료로 시작'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _yearly ? '7일 무료 체험 후 연 19,900원. 언제든 해지할 수 있어요.' : '7일 무료 체험 후 월 2,900원. 언제든 해지할 수 있어요.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
            if (!store.available) ...[
              const SizedBox(height: AppSpacing.md),
              InfoBox(icon: Symbols.info_rounded, child: Text('결제는 스토어 심사 후 열려요. 지금은 미리보기예요.', style: t.bodySmall)),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                  onPressed: store.busy ? null : _restore,
                  child: const Text('구매 복원'),
                ),
                Text('·', style: t.bodySmall),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                  onPressed: () => ExternalLinks.open(PaywallScreen.termsUrl),
                  child: const Text('이용약관'),
                ),
                Text('·', style: t.bodySmall),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                  onPressed: () => ExternalLinks.open(PaywallScreen.privacyUrl),
                  child: const Text('개인정보처리방침'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: context.colors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
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
