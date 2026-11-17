import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/paywall_trigger.dart';

/// 페이월을 띄운 계기. users/{uid}.paywallShown 에 1회씩 기록한다.
enum PaywallSource {
  reportBottom,
  streak3,
  share3,
  limitHit,
  featureTap,
  guide7,
  settings,
  /// featureTap 의 세부 (집 만들기 / 일정 추가 / 여러 장). 트리거 규칙은 featureTap 과 같다.
  household,
  calendar,
  multi,

  /// 1.2.1 전환 개선: 9회째 결과 배너 / 11회째 막힘 화면 / 질문 6회째 막힘 / 수거일 설정 직후 / 도감 10개 / 3주 연속(기존 streak3).
  limitWarning,
  limitBlock,
  chatLimitBlock,
  scheduleDone,
  collection10;

  bool get isFeatureTap => this == featureTap || this == household || this == calendar || this == multi;

  /// 사용자가 직접 누르는 버튼이라 "거절 7일 쿨다운" 을 적용하지 않는 곳: 설정 메뉴, 제한 막힘 화면 버튼.
  bool get isUserButton => this == settings || this == limitBlock || this == chatLimitBlock;

  /// 기분 좋을 때 소프트 진입(평생 1회, 72시간 뒤, 거절 쿨다운 적용).
  bool get isSoft => this == scheduleDone || this == collection10 || this == streak3;

  /// paywall_view.source 값.
  String get analyticsName => switch (this) {
        reportBottom => 'report',
        limitHit => 'limit',
        featureTap => 'feature_tap',
        limitWarning => 'limit_warning',
        limitBlock => 'limit_block',
        chatLimitBlock => 'chat_limit_block',
        scheduleDone => 'schedule_done',
        collection10 => 'collection_10',
        _ => name,
      };
}

/// 프리미엄이면 true. 아니면 (조건이 맞을 때) 페이월을 띄우고 결제 결과를 돌려준다.
///
/// 설치 72시간 안·온보딩 중·첫 제한 전처럼 페이월을 띄우지 않는 때는 짧은 잠금 안내만 보여준다.
Future<bool> ensurePremium(BuildContext context, {String? reason, String? unavailableMessage, PaywallSource source = PaywallSource.featureTap}) async {
  final services = AppServices.of(context);
  final premium = services.premium;
  if (premium.isPremium) return true;
  final shown = await maybeShowPaywall(context, source: source, reason: reason, userInitiated: source.isFeatureTap);
  if (shown == null) {
    if (context.mounted) await showLockedPlanSheet(context, reason: reason, message: unavailableMessage);
    return false;
  }
  return shown || premium.isPremium;
}

/// 조건이 맞으면 페이월을 띄우고 결과(true=결제됨)를, 조건이 안 맞으면 null 을 돌려준다.
Future<bool?> maybeShowPaywall(BuildContext context, {required PaywallSource source, String? reason, bool userInitiated = false}) async {
  final services = AppServices.of(context);
  final trigger = PaywallTrigger(await SharedPreferences.getInstance());
  if (!context.mounted) return null;
  if (source == PaywallSource.limitHit) await trigger.markLimitHit();
  if (!trigger.canShow(source, installedAt: services.settings.installedAt, onboarded: services.settings.onboarded, userInitiated: userInitiated)) return null;
  await trigger.markShown(source, remote: services.auth.service.mergeUserDoc);
  if (!context.mounted) return null;
  final ok = await context.pushPage<bool>(PaywallScreen(reason: reason, source: source));
  return ok == true;
}

/// 페이월을 띄우지 않을 때의 짧은 안내.
Future<void> showLockedPlanSheet(BuildContext context, {String? reason, String? message}) {
  return showAppSheet<void>(
    context,
    initialSize: 0.42,
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
              Icon(Symbols.lock_rounded, color: c.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(reason ?? '프리미엄에서 열려요', style: t.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message ?? '무료 횟수는 매일 자정에 다시 채워져요. 프리미엄은 설정 → 프리미엄에서 언제든 시작할 수 있어요.', style: t.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('알겠어요')),
        ],
      );
    },
  );
}
