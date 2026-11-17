import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/intro_animation.dart' show SpeechBubble;
import 'free_limits.dart';
import 'premium_gate.dart';
import 'premium_store.dart';

/// 어떤 한도에 걸렸나.
enum LimitKind { classify, chat }

/// 하루 한도(분류 10회 / 질문 5회)에 걸렸을 때의 막힘 화면.
/// 리뿅이(happy 120px) + 말풍선(뿅체) → 표준 문구 → [7일 무료로 시작] [내일 다시 올게요]. 프리미엄이 열리면 true.
Future<bool> showLimitBlockSheet(BuildContext context, {required LimitKind kind}) async {
  final services = AppServices.of(context);
  final count = kind == LimitKind.classify ? FreeLimits.classifyPerDay : FreeLimits.chatPerDay;
  final noun = kind == LimitKind.classify ? '분류' : '질문';
  final source = kind == LimitKind.classify ? PaywallSource.limitBlock : PaywallSource.chatLimitBlock;
  // 체험 자격은 상품 정보가 있을 때만 확실. 모르면 체험 문구로 (Play 가 자격 없는 사용자에겐 기본 요금제를 보여준다).
  final trial = services.premium.yearly == null || PremiumStore.trialEligible(services.premium.yearly) || PremiumStore.trialEligible(services.premium.monthly);
  Analytics.screen('limit_block');
  final go = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      final t = ctx.text;
      final c = ctx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: MascotImage(Mascot.happy, size: 120)),
            const SizedBox(height: AppSpacing.sm),
            Center(child: SpeechBubble(text: '오늘 $count개나 $noun했뿅! 대단하뿅.')),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '내일 다시 $count회 무료로 열려요. 지금 더 하려면 프리미엄 7일 무료 체험을 시작할 수 있어요.',
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: c.ink, foregroundColor: c.onInk),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(trial ? '7일 무료로 시작' : '프리미엄 시작하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: c.textSecondary, minimumSize: const Size.fromHeight(44)),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('내일 다시 올게요'),
            ),
          ],
        ),
      );
    },
  );
  if (go != true || !context.mounted) return false;
  final ok = await maybeShowPaywall(context, source: source, userInitiated: true);
  return ok == true || services.premium.isPremium;
}

/// 9회째(질문은 4회째) 뒤에 보이는 한 줄 예고. 탭하면 페이월(source=limit_warning).
class LimitWarningBanner extends StatelessWidget {
  const LimitWarningBanner({super.key, required this.kind});

  final LimitKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => maybeShowPaywall(context, source: PaywallSource.limitWarning, userInitiated: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text('오늘 1번 남았어요 · 프리미엄은 무제한', style: t.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right_rounded, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}
