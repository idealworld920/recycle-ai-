import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'paywall_screen.dart';

/// 프리미엄이면 true. 아니면 페이월을 띄우고 결제 결과를 돌려준다.
///
/// 스토어 결제가 아직 열리지 않은 빌드(RevenueCat 키 없음)에서는 페이월 대신
/// "곧 출시" 안내만 띄운다. 사용자가 살 수 없는 결제 화면을 보여주지 않기 위해서.
Future<bool> ensurePremium(BuildContext context, {String? reason, String? unavailableMessage}) async {
  final premium = AppServices.of(context).premium;
  if (premium.isPremium) return true;
  if (!premium.available) {
    await showPremiumSoonSheet(context, reason: reason, message: unavailableMessage);
    return false;
  }
  final ok = await context.pushPage<bool>(PaywallScreen(reason: reason));
  return ok == true || premium.isPremium;
}

/// 결제가 아직 안 열렸을 때 보여주는 짧은 안내.
Future<void> showPremiumSoonSheet(BuildContext context, {String? reason, String? message}) {
  return showAppSheet<void>(
    context,
    initialSize: 0.4,
    maxSize: 0.6,
    builder: (ctx, controller) {
      final c = ctx.colors;
      final t = ctx.text;
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          Row(
            children: [
              Icon(Symbols.workspace_premium_rounded, color: c.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(reason ?? 'ReSAI 프리미엄', style: t.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message ?? '무료 횟수는 매일 자정에 다시 채워져요. 무제한으로 쓸 수 있는 프리미엄은 곧 출시돼요.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('알겠어요')),
        ],
      );
    },
  );
}
