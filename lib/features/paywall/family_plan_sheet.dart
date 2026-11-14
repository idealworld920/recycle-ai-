import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../places/external_links.dart';
import '../premium/premium_store.dart';
import '../premium/purchase_errors.dart';
import '../premium/purchases_service.dart';

/// 설정 → 가족 플랜 관리. 상태·갱신일·Play 구독 관리·구매 복원. (리뿅이 없음)
Future<void> showFamilyPlanSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: '가족 플랜 관리',
    initialSize: 0.5,
    builder: (ctx, controller) {
      final services = AppServices.of(ctx);
      final p = services.premium;
      final t = ctx.text;
      final c = ctx.colors;
      return ListenableBuilder(
        listenable: p,
        builder: (ctx, _) {
          final status = switch (p.source) {
            PremiumSource.own => '내 구독으로 사용 중',
            PremiumSource.family => '집 방장의 구독으로 사용 중',
            PremiumSource.review => '검토 모드',
            PremiumSource.debug => '개발 모드',
            PremiumSource.none => '사용 안 함',
          };
          final renews = p.renewsAt;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            children: [
              AppCard(
                soft: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('상태', style: t.bodySmall),
                    Text(status, style: t.titleSmall),
                    if (renews != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(p.source == PremiumSource.own ? '다음 갱신' : '만료', style: t.bodySmall),
                      Text('${renews.year}.${renews.month.toString().padLeft(2, '0')}.${renews.day.toString().padLeft(2, '0')}', style: t.titleSmall),
                    ],
                    if (p.source == PremiumSource.family) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('방장이 해지하면 만료일 이후 모두 무료로 돌아가요. 기록은 그대로 남아요.', style: t.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (p.source == PremiumSource.own)
                OutlinedButton.icon(
                  onPressed: () => ExternalLinks.open(PremiumConfig.manageUrl(p.productId)),
                  icon: const Icon(Symbols.open_in_new_rounded, size: 18),
                  label: const Text('Google Play에서 구독 관리'),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                onPressed: p.busy || !p.available
                    ? null
                    : () async {
                        final r = await p.restore();
                        if (!ctx.mounted) return;
                        final msg = switch (r) {
                          PurchaseSuccess() => '구독을 복원했어요.',
                          PurchaseFailed(:final message) => message,
                          _ => null,
                        };
                        if (msg != null) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
                      },
                child: const Text('구매 복원'),
              ),
            ],
          );
        },
      );
    },
  );
}
