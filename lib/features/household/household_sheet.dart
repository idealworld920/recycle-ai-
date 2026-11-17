import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../auth/link_flows.dart';
import '../legal/legal_links.dart';
import '../premium/premium_gate.dart';
import 'household_model.dart';
import 'household_repository.dart';
import 'invite_code.dart';
import '../../core/analytics.dart';
import '../share/share_service.dart';

/// 멤버 색 번호 → 토큰 색.
Color memberColor(AppTokens c, int index) =>
    [c.primary, c.food, c.special, c.warningText, c.general, c.ink][index.clamp(0, HouseholdMember.memberColorCount - 1)];

/// 설정 → 우리 집.
Future<void> showHouseholdSheet(BuildContext context) {
  Analytics.screen('household_sheet');
  return showAppSheet(
    context,
    title: '우리 집',
    initialSize: 0.75,
    builder: (ctx, controller) => _HouseholdBody(controller: controller),
  );
}

class _HouseholdBody extends StatelessWidget {
  const _HouseholdBody({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final store = services.household;
    final t = context.text;
    final c = context.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([store, services.auth, services.premium]),
      builder: (context, _) {
        final h = store.household;
        if (h == null) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Text('가족·룸메와 수거일을 같이 봐요. 한 명이 바꾸면 모두에게 반영되고, 누가 버렸는지도 보여요.', style: t.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: store.busy ? null : () => _create(context),
                icon: const Icon(Symbols.add_home_rounded, size: 20),
                label: const Text('집 만들기'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('프리미엄 전용 · 최대 ${Household.maxMembers}명', style: t.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: store.busy ? null : () => _join(context),
                icon: const Icon(Symbols.pin_rounded, size: 20),
                label: const Text('코드로 참여'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('무료 · 구글 연결만 있으면 돼요', style: t.bodySmall, textAlign: TextAlign.center),
            ],
          );
        }
        final me = store.me;
        final expired = h.inviteExpiredAt(DateTime.now());
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          children: [
            AppCard(
              soft: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('초대 코드', style: t.bodySmall)),
                      if (store.isOwner)
                        TextButton(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 32)),
                          onPressed: store.busy ? null : () => store.regenerateInvite(),
                          child: const Text('재발급'),
                        ),
                    ],
                  ),
                  Text(h.inviteCode.isEmpty ? '------' : h.inviteCode, style: t.headlineSmall?.copyWith(fontSize: 32, letterSpacing: 4)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    expired ? '만료됐어요. 방장이 재발급하면 24시간 동안 다시 쓸 수 있어요.' : '${_remaining(h.inviteCodeExpiresAt!)} 남음 · 대소문자 구분 없음',
                    style: t.bodySmall?.copyWith(color: expired ? c.error : c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: expired || h.isFull
                        ? null
                        : () async {
                            final r = await SharePlus.instance.share(ShareParams(text: 'ReSAI 우리 집에 초대할게! 코드: ${h.inviteCode} ${LegalLinks.base}'));
                            if (r.status != ShareResultStatus.dismissed) Analytics.log('household_code_share', {'channel': ShareService.shareChannel(r.raw)});
                          },
                    icon: const Icon(Symbols.share_rounded, size: 20),
                    label: Text(h.isFull ? '정원이 찼어요 (${Household.maxMembers}명)' : '초대 공유'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Text('멤버 ${h.members.length}/${Household.maxMembers}', style: t.titleSmall)),
                if (store.familyPlanActive) Text('프리미엄 적용 중', style: t.bodySmall?.copyWith(color: c.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final m in h.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: memberColor(c, m.color), shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(m.nickname.isEmpty ? '이름 없음' : m.nickname, style: t.bodyMedium)),
                    if (m.uid == h.ownerUid) Text('방장', style: t.bodySmall?.copyWith(color: c.primary)),
                    if (m.uid == me?.uid) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text('(나)', style: t.bodySmall),
                      IconButton(
                        tooltip: '이름 바꾸기',
                        iconSize: 18,
                        color: c.textSecondary,
                        onPressed: store.busy
                            ? null
                            : () async {
                                final name = await _askNickname(context, m.nickname);
                                if (name == null || name == m.nickname || !context.mounted) return;
                                try {
                                  await store.setMyName(name);
                                } on HouseholdException catch (e) {
                                  if (context.mounted) _toast(context, e.message);
                                }
                              },
                        icon: const Icon(Symbols.edit_rounded),
                      ),
                    ],
                    if (store.isOwner && m.uid != me?.uid)
                      PopupMenuButton<String>(
                        icon: Icon(Symbols.more_horiz_rounded, size: 20, color: c.textSecondary),
                        onSelected: (v) => v == 'transfer' ? _transfer(context, m) : _remove(context, m),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'transfer', child: Text('방장 위임')),
                          PopupMenuItem(value: 'remove', child: Text('내보내기')),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text('수거일은 집 단위로 공유돼요. 알림은 각자 폰에서 각자 설정한 시각에 와요.', style: t.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: c.textSecondary),
              onPressed: store.busy ? null : () => _leave(context),
              child: const Text('집 나가기'),
            ),
          ],
        );
      },
    );
  }

  static String _remaining(DateTime until) {
    final d = until.difference(DateTime.now());
    if (d.inHours >= 1) return '${d.inHours}시간';
    return '${d.inMinutes.clamp(1, 59)}분';
  }

  Future<void> _create(BuildContext context) async {
    final services = AppServices.of(context);
    if (services.auth.isAnonymous && !await requireLinkForFamily(context)) return;
    if (!context.mounted) return;
    if (!await ensurePremium(context, reason: '집 만들기는 프리미엄에서 열려요', source: PaywallSource.household)) return;
    if (!context.mounted) return;
    final nickname = await _askNickname(context, HouseholdMember.defaultNickname(services.auth.displayName));
    if (nickname == null || !context.mounted) return;
    try {
      await services.household.create(nickname);
      if (context.mounted) await _celebrate(context);
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (e) {
      if (context.mounted) _toast(context, '집을 만들지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> _join(BuildContext context) async {
    final services = AppServices.of(context);
    if (services.auth.isAnonymous && !await requireLinkForFamily(context)) return;
    if (!context.mounted) return;
    final input = await _askJoin(context, HouseholdMember.defaultNickname(services.auth.displayName));
    if (input == null || !context.mounted) return;
    final hadOwnSchedule = services.schedule.isConfigured;
    try {
      await services.household.join(input.$1, input.$2);
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
      return;
    } catch (e) {
      if (context.mounted) _toast(context, '참여하지 못했어요. 인터넷 연결을 확인해 주세요.');
      return;
    }
    if (!context.mounted) return;
    await _celebrate(context);
    if (!context.mounted) return;
    // 개인 수거일이 있고 집에도 수거일이 있으면 어느 쪽을 쓸지 묻는다.
    if (hadOwnSchedule && services.household.household?.schedule != null) {
      final follow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('집 설정으로 바꿀까요?'),
          content: const Text('집에 이미 수거일이 있어요. 집 설정을 따르면 멤버 모두 같은 날을 보고, 내 설정을 유지하면 알림은 내 설정대로 와요.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('내 설정 유지')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('집 설정으로')),
          ],
        ),
      );
      await services.household.setFollowSchedule(follow ?? true);
    }
  }

  /// 집 생성·참여 성공: 리뿅이 한마디.
  Future<void> _celebrate(BuildContext context) => showAppSheet<void>(
        context,
        initialSize: 0.3,
        maxSize: 0.4,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            const Center(child: MascotSay(mascot: Mascot.happy, text: '새 식구 왔뿅!', size: 88)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('좋아요')),
          ],
        ),
      );

  Future<void> _leave(BuildContext context) async {
    final services = AppServices.of(context);
    final c = context.colors;
    final alone = services.household.members.length <= 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alone ? '집을 삭제할까요?' : '집을 나갈까요?'),
        content: Text(alone
            ? '마지막 멤버라서 나가면 집이 삭제돼요. 수거일 설정은 내 기기에 그대로 남아요.'
            : (services.household.isOwner ? '방장이 나가면 가장 먼저 들어온 멤버가 방장이 돼요. 다시 참여하려면 초대 코드가 필요해요.' : '내 수거일 설정은 나가기 전 집 설정을 그대로 가져가요. 다시 참여하려면 초대 코드가 필요해요.')),
        actions: [
          TextButton(style: TextButton.styleFrom(foregroundColor: c.textSecondary), onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(style: TextButton.styleFrom(foregroundColor: c.error), onPressed: () => Navigator.pop(ctx, true), child: Text(alone ? '삭제' : '나가기')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await services.household.leave();
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _remove(BuildContext context, HouseholdMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${m.nickname} 님을 내보낼까요?'),
        content: const Text('내보낸 멤버는 초대 코드로 다시 들어올 수 있어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(style: TextButton.styleFrom(foregroundColor: ctx.colors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('내보내기')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await AppServices.of(context).household.removeMember(m.uid);
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _transfer(BuildContext context, HouseholdMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${m.nickname} 님에게 방장을 넘길까요?'),
        content: const Text('프리미엄은 방장의 구독으로 열려요. 방장이 바뀌면 새 방장의 구독 상태를 따라요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('위임')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await AppServices.of(context).household.transferOwner(m.uid);
    } on HouseholdException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  void _toast(BuildContext context, String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<String?> _askNickname(BuildContext context, String initial) async {
    final ctrl = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('집에서 부를 이름'),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 10, decoration: const InputDecoration(hintText: '예: 엄마, 민수')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('확인')),
        ],
      ),
    );
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<(String, String)?> _askJoin(BuildContext context, String initialNick) async {
    final code = TextEditingController();
    final nick = TextEditingController(text: initialNick);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('코드로 참여'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: InviteCode.length,
              decoration: const InputDecoration(hintText: '6자리 초대 코드'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: nick, maxLength: 10, decoration: const InputDecoration(hintText: '집에서 부를 이름')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('참여')),
        ],
      ),
    );
    final normalized = InviteCode.normalize(code.text);
    if (ok != true || !InviteCode.isValid(normalized) || nick.text.trim().isEmpty) {
      if (ok == true && context.mounted) _toast(context, '초대 코드는 영문·숫자 6자리예요.');
      return null;
    }
    return (normalized, nick.text.trim());
  }
}
