import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../auth/link_flows.dart';
import '../places/external_links.dart';
import 'purchases_service.dart';

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
  bool _askedLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = AppServices.of(context);
      // 복원을 위해 연결을 권장 (필수 아님). 한 번만. 구독이 없는 동안은 묻지 않는다.
      if (services.premium.available && !_askedLink && services.auth.isAnonymous && mounted) {
        _askedLink = true;
        await recommendLinkBeforePurchase(context);
      }
    });
  }

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
            InfoBox(icon: Symbols.info_rounded, child: Text(PremiumConfig.comingSoon, style: t.bodySmall)),
            const SizedBox(height: AppSpacing.md),
            Text('구독이 열리면 월 2,900원 · 연 19,900원(7일 무료 체험)으로 시작할 수 있게 준비하고 있어요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
