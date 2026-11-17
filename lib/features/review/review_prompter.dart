import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 인앱 리뷰 요청. 조건: 설치 24시간 경과 AND (분류 성공 3회째 결과 화면 2초 뒤 OR 수거일 체크인 2회째) 중 먼저 오는 쪽.
/// 리뿅이 말풍선 3초 → InAppReview.requestReview(). 요청 뒤 90일 재요청 금지(users/{uid}.reviewPromptAt). 구독한 세션에선 안 묻는다.
class ReviewPrompter {
  ReviewPrompter._();

  static const minInstallAge = Duration(hours: 24);
  static const cooldown = Duration(days: 90);
  static const classifyTrigger = 3;
  static const checkinTrigger = 2;
  static const bubbleDelay = Duration(seconds: 3);
  static const line = '리뿅이 어때뿅? 별점 주면 힘나뿅!';

  static const classifyCounter = 'review_classify_count';
  static const checkinCounter = 'review_checkin_count';

  /// 이번 세션에 구독을 시작했으면 true (페이월이 켠다). 이 세션에선 리뷰를 묻지 않는다.
  static bool purchasedThisSession = false;

  /// 테스트용 훅. null 이면 in_app_review.
  static Future<bool> Function()? requestOverride;

  static bool _showing = false;

  /// 순수 조건 판단.
  static bool eligible({
    required DateTime installedAt,
    required DateTime? lastPromptAt,
    required DateTime now,
    bool purchasedThisSession = false,
  }) {
    if (purchasedThisSession) return false;
    if (now.difference(installedAt) < minInstallAge) return false;
    if (lastPromptAt != null && now.difference(lastPromptAt) < cooldown) return false;
    return true;
  }

  /// 분류 성공마다 (결과 화면). 3회째면 2초 뒤 묻는다.
  static Future<void> afterClassify(BuildContext context) async {
    final settings = AppServices.of(context).settings;
    final n = await settings.bump(classifyCounter);
    if (n != classifyTrigger) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (context.mounted) await maybePrompt(context);
  }

  /// 수거일 체크인마다. 2회째면 바로 묻는다.
  static Future<void> afterCheckin(BuildContext context) async {
    final settings = AppServices.of(context).settings;
    final n = await settings.bump(checkinCounter);
    if (n != checkinTrigger) return;
    if (context.mounted) await maybePrompt(context);
  }

  static Future<void> maybePrompt(BuildContext context) async {
    if (_showing) return;
    final services = AppServices.of(context);
    final settings = services.settings;
    if (!eligible(installedAt: settings.installedAt, lastPromptAt: settings.reviewPromptAt, now: DateTime.now(), purchasedThisSession: purchasedThisSession)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _showing = true;
    // 묻기로 한 시점에 기록해 둔다 (중간에 앱을 꺼도 90일 쿨다운은 지킨다).
    await settings.markReviewPrompted(remote: services.auth.service.mergeUserDoc);
    final dismissed = Completer<bool>();
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) => _ReviewBubble(onClose: () => dismissed.isCompleted ? null : dismissed.complete(true)));
    overlay.insert(entry);
    final timer = Timer(bubbleDelay, () => dismissed.isCompleted ? null : dismissed.complete(false));
    final closedEarly = await dismissed.future;
    timer.cancel();
    entry.remove();
    _showing = false;
    if (closedEarly) {
      await Analytics.log('review_prompt_dismissed');
      return;
    }
    await Analytics.log('review_prompt_shown');
    try {
      final ok = await (requestOverride?.call() ?? _request());
      if (!ok) debugPrint('[review] 요청 불가 (미지원 기기)');
    } catch (e) {
      debugPrint('[review] 요청 실패(무시): $e'); // 실패·미지원은 조용히
    }
  }

  static Future<bool> _request() async {
    final r = InAppReview.instance;
    if (!await r.isAvailable()) return false;
    await r.requestReview();
    return true;
  }
}

/// 상단에 3초 떠 있는 리뿅이 말풍선. X 로 닫으면 리뷰를 묻지 않는다.
class _ReviewBubble extends StatelessWidget {
  const _ReviewBubble({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: MediaQuery.paddingOf(context).top + AppSpacing.md,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              const Expanded(child: MascotSay(mascot: Mascot.happy, text: ReviewPrompter.line, size: 48)),
              IconButton(onPressed: onClose, tooltip: '닫기', iconSize: 18, color: c.textSecondary, icon: const Icon(Symbols.close_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}
