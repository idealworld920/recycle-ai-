import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/intro_animation.dart';
import '../premium/premium_gate.dart';
import '../places/region_picker_sheet.dart';
import '../schedule/pickup_schedule.dart';
import '../schedule/schedule_settings_sheet.dart';
import 'guide_steps.dart';
import 'ribbong_lines.dart';

/// 홈 상단 상주 리뿅이(72px) + 말풍선. 탭하면 반응, 5연타면 "간지럽뿅!!". 도감 뱃지·프리미엄 왕관.
class HomeRibbong extends StatefulWidget {
  const HomeRibbong({super.key, required this.lines});

  final RibbongLines lines;

  static const tickleTaps = 5;
  static const tickleWindow = Duration(seconds: 3);
  static const reactionLength = Duration(milliseconds: 1600);

  /// 도감 뱃지: 10 🌱 / 30 🌿 / 50 🌳.
  static String? collectionBadge(int collected) => collected >= 50 ? '🌳' : collected >= 30 ? '🌿' : collected >= 10 ? '🌱' : null;

  @override
  State<HomeRibbong> createState() => _HomeRibbongState();
}

class _HomeRibbongState extends State<HomeRibbong> {
  final _rnd = Random();
  Mascot _face = Mascot.idle;
  String? _reactionLine;
  Timer? _reactionTimer;
  final List<DateTime> _taps = [];
  String? _line;
  LineWhen? _lineWhen;

  @override
  void dispose() {
    _reactionTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    final now = DateTime.now();
    _taps.removeWhere((t) => now.difference(t) > HomeRibbong.tickleWindow);
    _taps.add(now);
    final tickle = _taps.length >= HomeRibbong.tickleTaps;
    if (tickle) _taps.clear();
    final reactions = <(Mascot, String?)>[
      (Mascot.randomHappy(_rnd), null),
      (Mascot.wink, null),
      (Mascot.thinking, null),
    ];
    final (face, line) = tickle ? (Mascot.randomHappy(_rnd), '간지럽뿅!!') : reactions[_rnd.nextInt(reactions.length)];
    setState(() {
      _face = face;
      _reactionLine = line;
    });
    _reactionTimer?.cancel();
    _reactionTimer = Timer(HomeRibbong.reactionLength, () {
      if (mounted) {
        setState(() {
          _face = Mascot.idle;
          _reactionLine = null;
        });
      }
    });
  }

  /// 가이드 버튼: 수거일 → 설정 시트, 지역 → 지역 선택, 프리미엄 → 페이월(paywallShown.guide7). 누르면 가이드는 닫힌다.
  Future<void> _guideAction(BuildContext context, GuideStep guide) async {
    final services = AppServices.of(context);
    await services.settings.dismissGuide(guide.key, remote: services.auth.service.mergeUserDoc);
    if (!context.mounted) return;
    switch (guide) {
      case GuideStep.schedule:
        await showScheduleSettingsSheet(context);
      case GuideStep.region:
        await showRegionPickerSheet(context);
      case GuideStep.premium:
        await maybeShowPaywall(context, source: PaywallSource.guide7, userInitiated: true, reason: '프리미엄 써보면 더 편해요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final c = context.colors;
    final t = context.text;
    return ListenableBuilder(
      listenable: Listenable.merge([services.schedule, services.history, services.collection, services.premium, services.settings, services.region]),
      builder: (context, _) {
        final now = DateTime.now();
        final snap = services.schedule.snapshot(now);
        final tomorrow = snap.upcoming.where((u) => u.daysUntil == 1).map((u) => u.type).toList();
        final todayCount = services.history.items.where((r) => PickupSchedule.dateKey(r.date) == PickupSchedule.dateKey(now)).length;
        final when = RibbongLines.decide(
          now: now,
          todayPickups: snap.today,
          tomorrowPickups: tomorrow,
          lastOpenedAt: services.settings.previousOpenedAt,
          classifiedToday: todayCount,
        );
        if (_lineWhen != when || _line == null) {
          _lineWhen = when;
          _line = widget.lines.pick(when, types: snap.today.isNotEmpty ? snap.today : tomorrow, rnd: _rnd);
        }
        final guide = GuideStep.current(
          daysSinceInstall: services.settings.daysSinceInstall,
          hasSchedule: services.schedule.isConfigured,
          hasRegion: services.region.isSet,
          isPremium: services.premium.isPremium,
          dismissed: services.settings.guideDismissed,
        );
        final text = _reactionLine ?? guide?.line ?? _line!;
        final badge = HomeRibbong.collectionBadge(services.collection.collected);
        final crown = services.premium.isPremium;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _onTap,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                label: '리뿅이',
                button: true,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: 4, top: 4, child: MascotImage(_face, size: 72)),
                      if (crown) Positioned(right: 0, top: 0, child: Icon(Symbols.crown_rounded, size: 16, color: c.warningText, fill: 1)),
                      if (badge != null) Positioned(right: 0, bottom: 0, child: Text(badge, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SpeechBubble(text: text, tail: BubbleTail.left),
                  if (guide != null && _reactionLine == null)
                    Positioned(
                      right: 0,
                      bottom: -22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 28), textStyle: t.bodySmall),
                            onPressed: () => _guideAction(context, guide),
                            child: Text(guide.actionLabel),
                          ),
                          IconButton(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            tooltip: '닫기',
                            color: c.textSecondary,
                            onPressed: () => services.settings.dismissGuide(guide.key, remote: services.auth.service.mergeUserDoc),
                            icon: const Icon(Symbols.close_rounded),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
