import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../premium/premium_gate.dart';
import 'paywall_trigger.dart';

/// "기분 좋을 때" 소프트 페이월 진입 3종. 각각 평생 1회, 설치 72시간 뒤, 페이월 거절 7일 안엔 쉼, 프리미엄이면 안 띄움.
class SoftPrompts {
  SoftPrompts._();

  static Future<PaywallTrigger?> _gate(BuildContext context, PaywallSource source) async {
    final services = AppServices.of(context);
    if (services.premium.isPremium) return null;
    final trigger = PaywallTrigger(await SharedPreferences.getInstance());
    if (!trigger.canShowSoft(source, installedAt: services.settings.installedAt, onboarded: services.settings.onboarded)) return null;
    await trigger.markSoftShown(source);
    return trigger;
  }

  /// 수거일 설정 완료 직후: "가족이나 룸메한테도 알려줄까요?" [같이 쓰기] [나중에]
  static Future<void> afterScheduleSaved(BuildContext context) async {
    if (await _gate(context, PaywallSource.scheduleDone) == null || !context.mounted) return;
    Analytics.screen('soft_schedule_done');
    final go = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => _SoftSheet(
        icon: Symbols.family_restroom_rounded,
        title: '가족이나 룸메한테도 알려줄까요?',
        body: '프리미엄은 한 명만 구독하면 집 전체(6명까지)가 같이 써요. 수거일도 같이 보고, 누가 버렸는지도 알 수 있어요.',
        primary: '같이 쓰기',
        secondary: '나중에',
      ),
    );
    if (go == true && context.mounted) await maybeShowPaywall(context, source: PaywallSource.scheduleDone, userInitiated: true);
  }

  /// 도감 10개 달성 축하 + 하단 한 줄 "여러 장 한 번에 찍으면 도감이 더 빨리 채워져요 →"
  static Future<void> atCollection10(BuildContext context) async {
    if (await _gate(context, PaywallSource.collection10) == null || !context.mounted) return;
    Analytics.screen('soft_collection_10');
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
              const Center(child: MascotImage(Mascot.cheer, size: 120)),
              const SizedBox(height: AppSpacing.md),
              Text('🌱 도감 10개 달성!', style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('첫 번째 뱃지를 받았어요. 홈 리뿅이 옆에 새싹이 생겨요.', style: t.bodyMedium?.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('좋아요')),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('여러 장 한 번에 찍으면 도감이 더 빨리 채워져요 →'),
              ),
            ],
          ),
        );
      },
    );
    if (go == true && context.mounted) await maybeShowPaywall(context, source: PaywallSource.collection10, userInitiated: true);
  }

  /// 수거일 체크인 3주 연속: 리뿅이 "3주 연속이뿅! 꾸준하뿅!" + "7일 무료로 프리미엄 써보기"
  static Future<void> atStreak3(BuildContext context) async {
    if (await _gate(context, PaywallSource.streak3) == null || !context.mounted) return;
    Analytics.screen('soft_streak_3');
    final go = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final c = ctx.colors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MascotSay(mascot: Mascot.cheer, text: '3주 연속이뿅! 꾸준하뿅!', size: 72),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.primary, minimumSize: const Size.fromHeight(44)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('7일 무료로 프리미엄 써보기'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.textSecondary, minimumSize: const Size.fromHeight(44)),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
    if (go == true && context.mounted) await maybeShowPaywall(context, source: PaywallSource.streak3, userInitiated: true);
  }
}

/// 표준 존댓말 소프트 시트 (리뿅이 없음).
class _SoftSheet extends StatelessWidget {
  const _SoftSheet({required this.icon, required this.title, required this.body, required this.primary, required this.secondary});

  final IconData icon;
  final String title;
  final String body;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: c.primary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: Text(secondary))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.onInk),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
